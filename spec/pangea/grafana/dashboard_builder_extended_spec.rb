# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pangea::Grafana::DashboardBuilder do
  describe '.build without a block' do
    it 'produces a valid empty dashboard' do
      json = described_class.build(title: 'Empty', uid: 'empty')
      dashboard = JSON.parse(json)

      expect(dashboard['panels']).to eq([])
      expect(dashboard['templating']['list']).to eq([])
      expect(dashboard['title']).to eq('Empty')
      expect(dashboard['uid']).to eq('empty')
    end
  end

  describe 'custom time range' do
    it 'uses provided time_from and time_to' do
      json = described_class.build(title: 'T', uid: 't', time_from: 'now-24h', time_to: 'now-1h')
      dashboard = JSON.parse(json)

      expect(dashboard['time']['from']).to eq('now-24h')
      expect(dashboard['time']['to']).to eq('now-1h')
    end

    it 'defaults to now-1h / now' do
      json = described_class.build(title: 'T', uid: 't')
      dashboard = JSON.parse(json)

      expect(dashboard['time']['from']).to eq('now-1h')
      expect(dashboard['time']['to']).to eq('now')
    end
  end

  describe '#gauge' do
    it 'generates a gauge panel with min/max and options' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.gauge('Disk Usage', unit: 'percentunit', min: 0, max: 100) do |p|
          p.query('disk_used_percent')
          p.threshold(0, color: 'green')
          p.threshold(80, color: 'red')
        end
      end
      dashboard = JSON.parse(json)
      panel = dashboard['panels'][0]

      expect(panel['type']).to eq('gauge')
      expect(panel['title']).to eq('Disk Usage')
      expect(panel['fieldConfig']['defaults']['unit']).to eq('percentunit')
      expect(panel['fieldConfig']['defaults']['min']).to eq(0)
      expect(panel['fieldConfig']['defaults']['max']).to eq(100)
      expect(panel['options']).to have_key('reduceOptions')
      expect(panel['options']['reduceOptions']['calcs']).to eq(['lastNotNull'])
      expect(panel['fieldConfig']['defaults']['thresholds']['mode']).to eq('absolute')
      expect(panel['fieldConfig']['defaults']['thresholds']['steps'].size).to eq(2)
    end

    it 'uses default width=6 and height=4' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.gauge('G') { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      panel = dashboard['panels'][0]

      expect(panel['gridPos']['w']).to eq(6)
      expect(panel['gridPos']['h']).to eq(4)
    end
  end

  describe '#table' do
    it 'generates a table panel with default full-width sizing' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.table('Logs') do |p|
          p.query('count_over_time({job="app"}[5m])')
        end
      end
      dashboard = JSON.parse(json)
      panel = dashboard['panels'][0]

      expect(panel['type']).to eq('table')
      expect(panel['title']).to eq('Logs')
      expect(panel['gridPos']['w']).to eq(24)
      expect(panel['gridPos']['h']).to eq(8)
      expect(panel['targets'].size).to eq(1)
    end

    it 'does not include stat/gauge options' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.table('T') { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      panel = dashboard['panels'][0]

      expect(panel).not_to have_key('options')
    end
  end

  describe 'panel grid layout and wrapping' do
    it 'places panels side by side when total width <= 24' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.stat('A', width: 6) { |p| p.query('up') }
        d.stat('B', width: 6) { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      panels = dashboard['panels']

      expect(panels[0]['gridPos']['x']).to eq(0)
      expect(panels[0]['gridPos']['y']).to eq(0)
      expect(panels[1]['gridPos']['x']).to eq(6)
      expect(panels[1]['gridPos']['y']).to eq(0)
    end

    it 'wraps to next row when total width exceeds 24' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.timeseries('A', width: 12) { |p| p.query('up') }
        d.timeseries('B', width: 12) { |p| p.query('up') }
        d.timeseries('C', width: 12) { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      panels = dashboard['panels']

      expect(panels[0]['gridPos']['x']).to eq(0)
      expect(panels[0]['gridPos']['y']).to eq(0)
      expect(panels[1]['gridPos']['x']).to eq(12)
      expect(panels[1]['gridPos']['y']).to eq(0)
      expect(panels[2]['gridPos']['x']).to eq(0)
      expect(panels[2]['gridPos']['y']).to be > 0
    end

    it 'advances y after a full-width panel' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.table('Full', width: 24, height: 8) { |p| p.query('up') }
        d.stat('After', width: 6) { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      panels = dashboard['panels']

      expect(panels[1]['gridPos']['y']).to eq(8)
      expect(panels[1]['gridPos']['x']).to eq(0)
    end
  end

  describe 'timeseries panel field config' do
    it 'includes custom fillOpacity and lineWidth' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.timeseries('M', fill: 25, line_width: 3) { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      custom = dashboard['panels'][0]['fieldConfig']['defaults']['custom']

      expect(custom['fillOpacity']).to eq(25)
      expect(custom['lineWidth']).to eq(3)
    end

    it 'uses default fill=10 and line_width=2' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.timeseries('M') { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      custom = dashboard['panels'][0]['fieldConfig']['defaults']['custom']

      expect(custom['fillOpacity']).to eq(10)
      expect(custom['lineWidth']).to eq(2)
    end

    it 'does not include custom block for non-timeseries panels' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.stat('S') { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      defaults = dashboard['panels'][0]['fieldConfig']['defaults']

      expect(defaults).not_to have_key('custom')
    end
  end

  describe 'panels without queries' do
    it 'produces empty targets array when no queries given' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.timeseries('Empty')
      end
      dashboard = JSON.parse(json)

      expect(dashboard['panels'][0]['targets']).to eq([])
    end
  end

  describe 'panels without unit' do
    it 'omits unit from field config when not specified' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.stat('No Unit') { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      defaults = dashboard['panels'][0]['fieldConfig']['defaults']

      expect(defaults).not_to have_key('unit')
    end
  end

  describe 'query variable type' do
    it 'generates query-type variable with datasource reference' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.variable(:env, type: :query, query: 'label_values(up, environment)')
      end
      dashboard = JSON.parse(json)
      var = dashboard['templating']['list'][0]

      expect(var['type']).to eq('query')
      expect(var['query']).to eq('label_values(up, environment)')
      expect(var['datasource']['uid']).to eq('${datasource}')
      expect(var['refresh']).to eq(2)
      expect(var['sort']).to eq(1)
    end

    it 'datasource variable does not include datasource reference or sort' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.variable(:ds, type: :datasource, query: 'prometheus')
      end
      dashboard = JSON.parse(json)
      var = dashboard['templating']['list'][0]

      expect(var['type']).to eq('datasource')
      expect(var['refresh']).to eq(1)
      expect(var).not_to have_key('datasource')
      expect(var).not_to have_key('sort')
      expect(var['includeAll']).to eq(false)
      expect(var['multi']).to eq(false)
    end
  end

  describe 'variable hide parameter' do
    it 'sets the hide value on the variable' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.variable(:hidden_var, type: :datasource, query: 'prometheus', hide: 2)
      end
      dashboard = JSON.parse(json)
      var = dashboard['templating']['list'][0]

      expect(var['hide']).to eq(2)
    end

    it 'defaults hide to 0' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.variable(:visible, type: :datasource, query: 'prometheus')
      end
      dashboard = JSON.parse(json)
      var = dashboard['templating']['list'][0]

      expect(var['hide']).to eq(0)
    end
  end

  describe 'variable custom label' do
    it 'uses provided label' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.variable(:ds, type: :datasource, query: 'prometheus', label: 'My DS')
      end
      dashboard = JSON.parse(json)
      var = dashboard['templating']['list'][0]

      expect(var['label']).to eq('My DS')
    end

    it 'auto-capitalizes name when no label given' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.variable(:datasource, type: :datasource, query: 'prometheus')
      end
      dashboard = JSON.parse(json)
      var = dashboard['templating']['list'][0]

      expect(var['label']).to eq('Datasource')
    end
  end

  describe 'multiple variables' do
    it 'preserves variable ordering' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.variable(:datasource, type: :datasource, query: 'prometheus')
        d.variable(:env, type: :query, query: 'label_values(up, env)')
        d.variable(:job, type: :query, query: 'label_values(up, job)')
      end
      dashboard = JSON.parse(json)
      names = dashboard['templating']['list'].map { |v| v['name'] }

      expect(names).to eq(%w[datasource env job])
    end
  end

  describe 'panel thresholds' do
    it 'omits thresholds block when no thresholds set' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.stat('S') { |p| p.query('up') }
      end
      dashboard = JSON.parse(json)
      defaults = dashboard['panels'][0]['fieldConfig']['defaults']

      expect(defaults).not_to have_key('thresholds')
    end

    it 'includes thresholds with correct color and value' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.stat('S') do |p|
          p.query('up')
          p.threshold(0, color: 'green')
          p.threshold(90, color: 'yellow')
          p.threshold(95, color: 'red')
        end
      end
      dashboard = JSON.parse(json)
      steps = dashboard['panels'][0]['fieldConfig']['defaults']['thresholds']['steps']

      expect(steps.size).to eq(3)
      expect(steps[0]).to eq({ 'color' => 'green', 'value' => 0 })
      expect(steps[2]).to eq({ 'color' => 'red', 'value' => 95 })
    end
  end

  describe 'RowContext delegation' do
    it 'delegates gauge to builder' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.row('Section') do |r|
          r.gauge('Gauge') { |p| p.query('up') }
        end
      end
      dashboard = JSON.parse(json)
      gauge_panels = dashboard['panels'].select { |p| p['type'] == 'gauge' }

      expect(gauge_panels.size).to eq(1)
      expect(gauge_panels[0]['title']).to eq('Gauge')
    end

    it 'delegates table to builder' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.row('Section') do |r|
          r.table('Table') { |p| p.query('up') }
        end
      end
      dashboard = JSON.parse(json)
      table_panels = dashboard['panels'].select { |p| p['type'] == 'table' }

      expect(table_panels.size).to eq(1)
    end

    it 'delegates stat to builder' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.row('Section') do |r|
          r.stat('Stat') { |p| p.query('up') }
        end
      end
      dashboard = JSON.parse(json)
      stat_panels = dashboard['panels'].select { |p| p['type'] == 'stat' }

      expect(stat_panels.size).to eq(1)
    end
  end

  describe 'row panel structure' do
    it 'creates row with type, title, and gridPos' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.row('My Row')
      end
      dashboard = JSON.parse(json)
      row = dashboard['panels'][0]

      expect(row['type']).to eq('row')
      expect(row['title']).to eq('My Row')
      expect(row['collapsed']).to eq(false)
      expect(row['gridPos']['h']).to eq(1)
      expect(row['gridPos']['w']).to eq(24)
      expect(row['gridPos']['x']).to eq(0)
    end

    it 'assigns unique IDs to row and nested panels' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.row('R') do |r|
          r.timeseries('P1') { |p| p.query('up') }
        end
      end
      dashboard = JSON.parse(json)
      ids = dashboard['panels'].map { |p| p['id'] }

      expect(ids.uniq.size).to eq(ids.size)
    end
  end

  describe 'explicit ref_id on query' do
    it 'uses the explicitly provided ref_id' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.timeseries('M') do |p|
          p.query('up', ref_id: 'X')
          p.query('down', ref_id: 'Y')
        end
      end
      dashboard = JSON.parse(json)
      refs = dashboard['panels'][0]['targets'].map { |t| t['refId'] }

      expect(refs).to eq(%w[X Y])
    end
  end

  describe '#to_hash structure' do
    it 'includes all expected top-level keys' do
      builder = described_class.new(title: 'T', uid: 't')
      hash = builder.to_hash

      expected_keys = %w[annotations description editable fiscalYearStartMonth
                         graphTooltip id links panels schemaVersion tags
                         templating time timepicker timezone title uid version]
      expect(hash.keys.sort).to eq(expected_keys.sort)
    end

    it 'has null id and version 1' do
      builder = described_class.new(title: 'T', uid: 't')
      hash = builder.to_hash

      expect(hash['id']).to be_nil
      expect(hash['version']).to eq(1)
    end
  end

  describe 'multiple rows with panels' do
    it 'places panels after their respective rows' do
      json = described_class.build(title: 'T', uid: 't') do |d|
        d.row('R1') do |r|
          r.timeseries('P1', width: 24) { |p| p.query('up') }
        end
        d.row('R2') do |r|
          r.timeseries('P2', width: 24) { |p| p.query('down') }
        end
      end
      dashboard = JSON.parse(json)
      panels = dashboard['panels']

      rows = panels.select { |p| p['type'] == 'row' }
      expect(rows.size).to eq(2)
      expect(rows[0]['gridPos']['y']).to be < rows[1]['gridPos']['y']
    end
  end
end
