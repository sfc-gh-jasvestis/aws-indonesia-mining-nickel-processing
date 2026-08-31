'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';
import { GeoMap } from '@/components/GeoMap';
import { ArchitectureDiagram } from '@/components/ArchitectureDiagram';

interface DemoNarrative {
  title: string;
  duration: string;
  thesis: string;
  tabs: any[];
}

export default function HomePage() {
  const [narrative, setNarrative] = useState<DemoNarrative | null>(null);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch('/demo_narrative.json')
      .then((r) => r.json())
      .then(setNarrative)
      .catch(() => {});
    fetch('/api/data')
      .then((r) => r.json())
      .then(setData)
      .catch(() => {});
  }, []);

  const title = narrative?.title || 'SEA AWS Demo';

  const executiveCockpit = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard title="NPI Output (MTD)" value="42K tonnes" status="neutral" />
        <KPICard title="Recovery Rate" value="89.2%" status="neutral" />
        <KPICard title="Energy Cost" value="Rp 847B" status="warning" />
        <KPICard title="Kilns Active" value="24/28" status="neutral" />
      </div>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="lg:col-span-1">
          <GeoMap
            country="indonesia"
            markers={[{"label": "Morowali", "value": "IMIP: 42K t NPI/mo", "color": "green", "size": "lg"}, {"label": "Halmahera", "value": "Ore: 1.2M WMT", "color": "green", "size": "lg"}, {"label": "Obi Island", "value": "Port queue: 7 days", "color": "red", "size": "md"}, {"label": "Jakarta", "value": "Trading HQ", "color": "blue", "size": "md"}, {"label": "Makassar", "value": "Logistics hub", "color": "blue", "size": "sm"}]}
            routes={[{"from": "Halmahera", "to": "Morowali", "color": "#29B5E8"}, {"from": "Morowali", "to": "Makassar", "color": "#10B981"}]}
            title="Geographic Overview"
            height={400}
          />
        </div>
        <div className="lg:col-span-1 grid grid-cols-1 gap-4">
      <div className="grid grid-cols-1 gap-4 grid-cols-1">
        <Chart
          data={data?.timeseries || [{ period: 'Loading', value: 0 }]}
          type="line"
          xKey="period"
          yKeys={[{ key: 'value', name: 'Tonnes' }]}
          title="NPI Production (Daily)"
        />
        <Chart
          data={data?.categories || [{ category: 'Loading', count: 0 }]}
          type="bar"
          xKey="category"
          yKeys={[{ key: 'count', name: '%' }]}
          title="Recovery Rate by Kiln"
        />
      </div>
        </div>
      </div>
      <DataTable
        columns={[
          { key: 'id', header: 'Kiln' },
          { key: 'name', header: 'Status' },
          { key: 'status', header: 'Efficiency' },
          { key: 'value', header: 'Output (T/d)' },
        ]}
        data={data?.entities || []}
        title="Kiln Performance"
      />
    </div>
  );

  const domainTab1 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KPICard title="Ore Grade Avg" value="1.8% Ni" />
        <KPICard title="Slag Ratio" value="12:1" />
        <KPICard title="Specific Energy" value="4.2 MWh/t" />
      </div>
      <Chart
        data={data?.detail || [{ x: 'Loading', y: 0 }]}
        type="area"
        xKey="x"
        yKeys={[{ key: 'y', name: 'MWh' }]}
        title="Energy Consumption by Process Stage"
        height={400}
      />
    </div>
  );

  const domainTab2 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart
          data={data?.breakdown || [{ label: 'A', value: 30 }, { label: 'B', value: 70 }]}
          type="pie"
          xKey="label"
          yKeys={[{ key: 'value', name: 'Score' }]}
          title="Equipment Health Score"
        />
        <ActionMemo
          persona={{ name: 'Ir. Hendra Kusuma', role: 'Smelter Plant Director' }}
          context={{}}
          onGenerate={async () => ({
            subject: 'Action Required',
            body: 'AI-generated recommendation based on current data patterns and predicted trends.',
            urgency: 'HIGH',
            actions: ['Schedule RKEF Kiln-3 relining (predicted wear)', 'Optimize ore blending for current grade mix', 'Investigate Kiln-7 recovery drop (dust loss suspected)'],
          })}
        />
      </div>
    </div>
  );

  const askAiTab = (
    <div className="h-[600px]">
      <AskAI
        title="Ask AI"
        sampleQuestions={[
          'Which kilns have below-target recovery rates?',
          'Show energy consumption trend vs nickel price',
          'What is the optimal ore blending ratio for current feed?',
        ]}
        mode="sql"
        onSubmit={async (question, mode) => {
          return {
            answer: `[Demo Mode] Response to: "${question}" (${mode} mode). Connect to Snowflake for live data.`,
            sql: mode === 'sql' ? 'SELECT * FROM CURATED.SUMMARY LIMIT 10;' : undefined,
          };
        }}
      />
    </div>
  );

  const architectureTab = (
    <ArchitectureDiagram
      snowflakeFeatures={['Dynamic Tables (5-min refresh)', 'ML Functions (Forecast + Anomaly)', 'Cortex Search + Agent', 'Semantic View + Intelligence', 'Alerts + Notifications']}
      awsServices={[{ name: 'Amazon S3', role: 'Strategy Docs' }, { name: 'Amazon S3 + Kinesis', role: 'Integration' }, { name: 'Amazon SNS', role: 'Integration' }, { name: 'Amazon QuickSight + Q', role: 'Integration' }]}
    />
  );

  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '📊', content: executiveCockpit },
    { id: 'domain-1', label: 'Process Optimization', icon: '📈', content: domainTab1 },
    { id: 'domain-2', label: 'Maintenance', icon: '⚡', content: domainTab2 },
    { id: 'ask-ai', label: 'Ask AI', icon: '🤖', content: askAiTab },
    { id: 'architecture', label: 'Architecture & Data', icon: '🏗️', content: architectureTab },
  ];

  return (
    <AppLayout
      title={title}
      tabs={tabs}
      narrative={narrative}
    />
  );
}
