import { NextResponse } from 'next/server';
import { executeQuery } from '@/lib/snowflake';
import { demoPlatform } from '@/lib/platform';

export const dynamic = 'force-dynamic';

// Only these fixed, read-only queries can run. The model never writes SQL; it
// only summarises rows returned here, so every answer is traceable to data.
const INTENTS: Record<string, { match: RegExp; sql: string }> = {
  upsets: {
    match: /upset|recovery|worst|lowest|line/i,
    sql: `SELECT ENTITY_ID, ENTITY_NAME, REGION, CATEGORY, UPSET_COUNT, ROUND(NI_RECOVERY_PCT, 2) AS NI_RECOVERY_PCT
FROM CURATED.PERFORMANCE_SUMMARY
QUALIFY DENSE_RANK() OVER (ORDER BY UPSET_COUNT DESC) <= 2
ORDER BY UPSET_COUNT DESC, NI_RECOVERY_PCT`,
  },
  causes: {
    match: /cause|root|why/i,
    sql: `SELECT ROOT_CAUSE, UPSET_COUNT, NI_LOST_T, DOWNTIME_HOURS
FROM CURATED.UPSET_CAUSES ORDER BY NI_LOST_T DESC LIMIT 5`,
  },
  kpis: {
    match: /.*/,
    sql: `SELECT TITLE, DISPLAY, SOURCE_WATERMARK FROM CURATED.KPI_SUMMARY ORDER BY SORT_ORDER`,
  },
};

const DEFINITIONS =
  'Nickel recovery = sum(nickel recovered t) / sum(nickel in feed t). Energy intensity = sum(energy MWh) / sum(dry ore processed t). ' +
  'A process upset is an unplanned line event (for example kiln ring build-up, electrode breakage or autoclave scale) that stops or degrades a line. ' +
  'All data is synthetic demo data.';

// provider 'cortex' = Snowflake AI_COMPLETE; 'bedrock' = Amazon Bedrock Claude
// via the external-access UDF APP.BEDROCK_GENERATE (aws/setup_aws.py).
async function summarise(question: string, rows: unknown[], provider: 'cortex' | 'bedrock' = 'cortex'): Promise<string> {
  const prompt =
    'You are a nickel processing analyst. Answer ONLY from the JSON rows and definitions below. ' +
    'If the rows do not answer the question, say so. Do not invent numbers. Keep it under 120 words.\n' +
    `Definitions: ${DEFINITIONS}\nRows: ${JSON.stringify(rows)}\nQuestion: ${question}`;
  const out = await executeQuery<{ R: string }>(
    provider === 'bedrock' ? 'SELECT APP.BEDROCK_GENERATE(?) AS R' : `SELECT AI_COMPLETE('claude-sonnet-4-5', ?) AS R`,
    [prompt],
  );
  const raw = String(out[0]?.R ?? '').trim();
  // AI_COMPLETE returns a JSON string literal; decode it when present.
  try {
    const parsed = JSON.parse(raw);
    return typeof parsed === 'string' ? parsed : raw;
  } catch {
    return raw;
  }
}

export async function POST(req: Request) {
  let body: any;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }
  const question = typeof body?.question === 'string' ? body.question.trim().slice(0, 2000) : '';
  const memo = body?.mode === 'memo';
  if (!memo && !question) return NextResponse.json({ error: 'Question required' }, { status: 400 });

  try {
    if (memo) {
      const provider = demoPlatform() === 'aws' ? 'bedrock' : 'cortex';
      const [kpis, upsets, causes, risk, bands] = await Promise.all([
        executeQuery(INTENTS.kpis.sql),
        executeQuery(INTENTS.upsets.sql),
        executeQuery(INTENTS.causes.sql),
        executeQuery(`SELECT ENTITY_ID, ROUND(UPSET_PROB_7D, 2) AS UPSET_PROB_7D, RISK_BAND
FROM ML.UPSET_RISK_SCORES ORDER BY UPSET_PROB_7D DESC LIMIT 5`),
        executeQuery(`SELECT RISK_BAND, COUNT(*) AS LINES FROM ML.UPSET_RISK_SCORES GROUP BY RISK_BAND`),
      ]);
      const rows = { kpis, topUpsetLines: upsets, topCauses: causes, top5ByRisk: risk, linesPerRiskBand: bands };
      const answer = await summarise(
        'Draft a short action memo for the VP Processing Operations with 3 prioritised actions, citing the figures.',
        [rows],
        provider,
      );
      return NextResponse.json({ answer, sources: rows, provider: provider === 'bedrock' ? 'Amazon Bedrock (Claude Sonnet 4.5)' : 'Snowflake Cortex AI_COMPLETE (claude-sonnet-4-5)', draft: true, synthetic: true });
    }
    const key = Object.keys(INTENTS).find((k) => INTENTS[k].match.test(question))!;
    const rows = await executeQuery(INTENTS[key].sql);
    const answer = await summarise(question, rows);
    return NextResponse.json({ answer, sql: INTENTS[key].sql, sources: rows, synthetic: true });
  } catch (err) {
    console.error('ask route failed', err);
    return NextResponse.json({ error: 'AI service unavailable' }, { status: 503 });
  }
}
