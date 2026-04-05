# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pangea::Grafana::DashboardBuilder do
  describe '.build' do
    it 'generates valid dashboard JSON with title and uid' do
      json = described_class.build(title: 'Test Dashboard', uid: 'test-dash')
      dashboard = JSON.parse(json)

      expect(dashboard['title']).to eq('Test Dashboard')
      expect(dashboard['uid']).to eq('test-dash')
      expect(dashboard['schemaVersion']).to eq(39)
      expect(dashboard['timezone']).to eq('utc')
    end

    it 'includes tags and description' do
      json = described_class.build(
        title: 'Test', uid: 'test',
        tags: ['a', 'b'], description: 'desc'
      )
      dashboard = JSON.parse(json)

      expect(dashboard['tags']).to eq(['a', 'b'])
      expect(dashboard['description']).to eq('desc')
    end

    it 'generates template variables' do
      json = described_class.build(title: 'Test', uid: 'test') do |d|
        d.variable(:datasource, type: :datasource, query: 'prometheus')
      end
      dashboard = JSON.parse(json)

      vars = dashboard['templating']['list']
      expect(vars.size).to eq(1)
      expect(vars[0]['name']).to eq('datasource')
      expect(vars[0]['type']).to eq('datasource')
      expect(vars[0]['query']).to eq('prometheus')
    end

    it 'generates timeseries panels with queries' do
      json = described_class.build(title: 'Test', uid: 'test') do |d|
        d.timeseries('CPU Usage', unit: 'percentunit') do |p|
          p.query('rate(cpu[1m])', legend: '{{pod}}')
          p.query('rate(cpu_limit[1m])', legend: 'limit')
        end
      end
      dashboard = JSON.parse(json)
      panels = dashboard['panels']

      expect(panels.size).to eq(1)
      expect(panels[0]['title']).to eq('CPU Usage')
      expect(panels[0]['type']).to eq('timeseries')
      expect(panels[0]['fieldConfig']['defaults']['unit']).to eq('percentunit')
      expect(panels[0]['targets'].size).to eq(2)
      expect(panels[0]['targets'][0]['expr']).to eq('rate(cpu[1m])')
      expect(panels[0]['targets'][0]['legendFormat']).to eq('{{pod}}')
    end

    it 'generates stat panels with thresholds' do
      json = described_class.build(title: 'Test', uid: 'test') do |d|
        d.stat('Rate', unit: 'ops', width: 6, height: 4) do |p|
          p.query('rate(requests[1m])')
          p.threshold(0, color: 'red')
          p.threshold(10, color: 'green')
        end
      end
      dashboard = JSON.parse(json)
      panel = dashboard['panels'][0]

      expect(panel['type']).to eq('stat')
      expect(panel['gridPos']['w']).to eq(6)
      expect(panel['gridPos']['h']).to eq(4)
      thresholds = panel['fieldConfig']['defaults']['thresholds']['steps']
      expect(thresholds.size).to eq(2)
      expect(thresholds[1]['color']).to eq('green')
    end

    it 'generates rows with nested panels' do
      json = described_class.build(title: 'Test', uid: 'test') do |d|
        d.row('Metrics') do |r|
          r.timeseries('Panel A') do |p|
            p.query('up')
          end
          r.timeseries('Panel B') do |p|
            p.query('down')
          end
        end
      end
      dashboard = JSON.parse(json)
      panels = dashboard['panels']

      # Row + 2 timeseries panels
      row_panels = panels.select { |p| p['type'] == 'row' }
      ts_panels = panels.select { |p| p['type'] == 'timeseries' }
      expect(row_panels.size).to eq(1)
      expect(row_panels[0]['title']).to eq('Metrics')
      expect(ts_panels.size).to eq(2)
    end

    it 'auto-assigns sequential panel IDs' do
      json = described_class.build(title: 'Test', uid: 'test') do |d|
        d.timeseries('A') { |p| p.query('up') }
        d.timeseries('B') { |p| p.query('down') }
      end
      dashboard = JSON.parse(json)
      ids = dashboard['panels'].map { |p| p['id'] }

      expect(ids).to eq([1, 2])
    end

    it 'auto-assigns ref IDs to queries' do
      json = described_class.build(title: 'Test', uid: 'test') do |d|
        d.timeseries('Multi') do |p|
          p.query('a')
          p.query('b')
          p.query('c')
        end
      end
      dashboard = JSON.parse(json)
      refs = dashboard['panels'][0]['targets'].map { |t| t['refId'] }

      expect(refs).to eq(%w[A B C])
    end

    it 'sets datasource from variable reference' do
      json = described_class.build(title: 'Test', uid: 'test') do |d|
        d.variable(:datasource, type: :datasource, query: 'prometheus')
        d.timeseries('M') { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      ds = dashboard['panels'][0]['datasource']

      expect(ds['uid']).to eq('${datasource}')
    end

    it 'produces deterministic JSON' do
      build = -> {
        described_class.build(title: 'Det', uid: 'det', tags: ['a']) do |d|
          d.timeseries('X') { |p| p.query('up') }
        end
      }
      expect(build.call).to eq(build.call)
    end
  end
end
