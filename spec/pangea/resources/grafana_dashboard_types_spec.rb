# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pangea::Resources::Grafana::Types::DashboardAttributes do
  describe 'required attributes' do
    it 'requires config_json' do
      expect { described_class.new({}) }.to raise_error(Dry::Struct::Error)
    end

    it 'accepts config_json as a string' do
      attrs = described_class.new(config_json: '{"title":"Test"}')
      expect(attrs.config_json).to eq('{"title":"Test"}')
    end

    it 'rejects non-string config_json' do
      expect { described_class.new(config_json: 123) }.to raise_error(Dry::Struct::Error)
    end
  end

  describe 'optional attributes' do
    let(:base) { { config_json: '{}' } }

    it 'defaults folder to Dry::Struct omitted' do
      attrs = described_class.new(base)
      expect(attrs.to_h).not_to have_key(:folder)
    end

    it 'accepts folder as a string' do
      attrs = described_class.new(base.merge(folder: 'my-folder'))
      expect(attrs.folder).to eq('my-folder')
    end

    it 'accepts folder as nil' do
      attrs = described_class.new(base.merge(folder: nil))
      expect(attrs.folder).to be_nil
    end

    it 'defaults overwrite to omitted' do
      attrs = described_class.new(base)
      expect(attrs.to_h).not_to have_key(:overwrite)
    end

    it 'accepts overwrite as true' do
      attrs = described_class.new(base.merge(overwrite: true))
      expect(attrs.overwrite).to eq(true)
    end

    it 'accepts overwrite as false' do
      attrs = described_class.new(base.merge(overwrite: false))
      expect(attrs.overwrite).to eq(false)
    end

    it 'accepts message as a string' do
      attrs = described_class.new(base.merge(message: 'deploy v1'))
      expect(attrs.message).to eq('deploy v1')
    end
  end

  describe 'transform_keys' do
    it 'converts string keys to symbols' do
      attrs = described_class.new('config_json' => '{}', 'folder' => 'f')
      expect(attrs.config_json).to eq('{}')
      expect(attrs.folder).to eq('f')
    end
  end
end
