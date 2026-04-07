# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pangea::Resources::Grafana::Types::DataSourceAttributes do
  describe 'required attributes' do
    it 'requires type, name, and url' do
      expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
    end

    it 'requires name when only type provided' do
      expect { described_class.new(type: 'prometheus') }.to raise_error(Dry::Struct::Error)
    end

    it 'requires url when only type and name provided' do
      expect { described_class.new(type: 'prometheus', name: 'prom') }.to raise_error(Dry::Struct::Error)
    end

    it 'accepts all three required attributes' do
      attrs = described_class.new(type: 'prometheus', name: 'prom', url: 'http://localhost:9090')
      expect(attrs.type).to eq('prometheus')
      expect(attrs.name).to eq('prom')
      expect(attrs.url).to eq('http://localhost:9090')
    end

    it 'rejects non-string type' do
      expect { described_class.new(type: 123, name: 'x', url: 'x') }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects non-string name' do
      expect { described_class.new(type: 'x', name: 123, url: 'x') }.to raise_error(Dry::Struct::Error)
    end

    it 'rejects non-string url' do
      expect { described_class.new(type: 'x', name: 'x', url: 123) }.to raise_error(Dry::Struct::Error)
    end
  end

  describe 'optional attributes' do
    let(:base) { { type: 'prometheus', name: 'prom', url: 'http://localhost:9090' } }

    it 'defaults uid to omitted' do
      attrs = described_class.new(base)
      expect(attrs.to_h).not_to have_key(:uid)
    end

    it 'accepts uid as a string' do
      attrs = described_class.new(base.merge(uid: 'ds-uid'))
      expect(attrs.uid).to eq('ds-uid')
    end

    it 'defaults is_default to omitted' do
      attrs = described_class.new(base)
      expect(attrs.to_h).not_to have_key(:is_default)
    end

    it 'accepts is_default as true' do
      attrs = described_class.new(base.merge(is_default: true))
      expect(attrs.is_default).to eq(true)
    end

    it 'accepts is_default as false' do
      attrs = described_class.new(base.merge(is_default: false))
      expect(attrs.is_default).to eq(false)
    end

    it 'rejects non-boolean is_default' do
      expect { described_class.new(base.merge(is_default: 'yes')) }.to raise_error(Dry::Struct::Error)
    end

    it 'defaults json_data_encoded to omitted' do
      attrs = described_class.new(base)
      expect(attrs.to_h).not_to have_key(:json_data_encoded)
    end

    it 'accepts json_data_encoded as a string' do
      attrs = described_class.new(base.merge(json_data_encoded: '{"httpMethod":"POST"}'))
      expect(attrs.json_data_encoded).to eq('{"httpMethod":"POST"}')
    end

    it 'defaults secure_json_data_encoded to omitted' do
      attrs = described_class.new(base)
      expect(attrs.to_h).not_to have_key(:secure_json_data_encoded)
    end

    it 'accepts secure_json_data_encoded as a string' do
      attrs = described_class.new(base.merge(secure_json_data_encoded: '{"password":"secret"}'))
      expect(attrs.secure_json_data_encoded).to eq('{"password":"secret"}')
    end
  end

  describe 'transform_keys' do
    it 'converts string keys to symbols' do
      attrs = described_class.new('type' => 'loki', 'name' => 'loki-ds', 'url' => 'http://loki:3100')
      expect(attrs.type).to eq('loki')
      expect(attrs.name).to eq('loki-ds')
      expect(attrs.url).to eq('http://loki:3100')
    end
  end

  describe 'all optional fields together' do
    it 'accepts all optional fields simultaneously' do
      attrs = described_class.new(
        type: 'prometheus',
        name: 'full',
        url: 'http://prom:9090',
        uid: 'uid-1',
        is_default: true,
        json_data_encoded: '{"a":1}',
        secure_json_data_encoded: '{"b":2}'
      )
      expect(attrs.uid).to eq('uid-1')
      expect(attrs.is_default).to eq(true)
      expect(attrs.json_data_encoded).to eq('{"a":1}')
      expect(attrs.secure_json_data_encoded).to eq('{"b":2}')
    end
  end
end
