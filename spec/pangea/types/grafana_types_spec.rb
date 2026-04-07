# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pangea::Resources::Grafana::Types do
  describe 'DashboardLayoutType' do
    subject(:type) { described_class::DashboardLayoutType }

    it 'accepts "ordered"' do
      expect(type['ordered']).to eq('ordered')
    end

    it 'accepts "free"' do
      expect(type['free']).to eq('free')
    end

    it 'rejects invalid layout types' do
      expect { type['grid'] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects empty string' do
      expect { type[''] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects nil' do
      expect { type[nil] }.to raise_error(Dry::Types::CoercionError)
    end
  end

  describe 'DatasourceType' do
    subject(:type) { described_class::DatasourceType }

    %w[prometheus loki tempo graphite elasticsearch influxdb mysql postgres].each do |valid_type|
      it "accepts '#{valid_type}'" do
        expect(type[valid_type]).to eq(valid_type)
      end
    end

    it 'rejects unknown datasource types' do
      expect { type['redis'] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects empty string' do
      expect { type[''] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects case-mismatched values' do
      expect { type['Prometheus'] }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'rejects nil' do
      expect { type[nil] }.to raise_error(Dry::Types::CoercionError)
    end
  end
end
