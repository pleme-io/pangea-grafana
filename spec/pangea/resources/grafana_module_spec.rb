# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pangea::Resources::Grafana do
  describe 'module registration' do
    it 'is registered in the ResourceRegistry' do
      expect(Pangea::ResourceRegistry.registered?(described_class)).to eq(true)
    end

    it 'appears in the list of registered modules' do
      expect(Pangea::ResourceRegistry.registered_modules).to include(described_class)
    end
  end

  describe 'module includes' do
    it 'includes GrafanaDashboard' do
      expect(described_class.ancestors).to include(Pangea::Resources::GrafanaDashboard)
    end

    it 'includes GrafanaFolder' do
      expect(described_class.ancestors).to include(Pangea::Resources::GrafanaFolder)
    end

    it 'includes GrafanaDataSource' do
      expect(described_class.ancestors).to include(Pangea::Resources::GrafanaDataSource)
    end
  end

  describe 'resource method availability' do
    it 'defines grafana_dashboard method' do
      expect(described_class.instance_methods).to include(:grafana_dashboard)
    end

    it 'defines grafana_folder method' do
      expect(described_class.instance_methods).to include(:grafana_folder)
    end

    it 'defines grafana_data_source method' do
      expect(described_class.instance_methods).to include(:grafana_data_source)
    end
  end
end

RSpec.describe PangeaGrafana do
  describe 'VERSION' do
    it 'is a semantic version string' do
      expect(PangeaGrafana::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end

    it 'is not nil or empty' do
      expect(PangeaGrafana::VERSION).not_to be_nil
      expect(PangeaGrafana::VERSION).not_to be_empty
    end
  end
end

RSpec.describe 'resource definitions' do
  describe Pangea::Resources::GrafanaDashboard do
    it 'has resource definitions registered' do
      expect(described_class.resource_definitions).to have_key(:grafana_dashboard)
    end

    it 'uses DashboardAttributes for validation' do
      defn = described_class.resource_definitions[:grafana_dashboard]
      expect(defn[:attributes_class]).to eq(Pangea::Resources::Grafana::Types::DashboardAttributes)
    end

    it 'maps config_json as a required attribute' do
      defn = described_class.resource_definitions[:grafana_dashboard]
      expect(defn[:map]).to include(:config_json)
    end

    it 'maps folder and message as present-only attributes' do
      defn = described_class.resource_definitions[:grafana_dashboard]
      expect(defn[:map_present]).to include(:folder)
      expect(defn[:map_present]).to include(:message)
    end

    it 'maps overwrite as a boolean attribute' do
      defn = described_class.resource_definitions[:grafana_dashboard]
      expect(defn[:map_bool]).to include(:overwrite)
    end

    it 'defines expected outputs' do
      defn = described_class.resource_definitions[:grafana_dashboard]
      expect(defn[:outputs]).to include(id: :id, uid: :uid, url: :url, version: :version, slug: :slug)
    end
  end

  describe Pangea::Resources::GrafanaFolder do
    it 'has resource definitions registered' do
      expect(described_class.resource_definitions).to have_key(:grafana_folder)
    end

    it 'uses FolderAttributes for validation' do
      defn = described_class.resource_definitions[:grafana_folder]
      expect(defn[:attributes_class]).to eq(Pangea::Resources::Grafana::Types::FolderAttributes)
    end

    it 'maps title as a required attribute' do
      defn = described_class.resource_definitions[:grafana_folder]
      expect(defn[:map]).to include(:title)
    end

    it 'maps uid and parent_folder_uid as present-only attributes' do
      defn = described_class.resource_definitions[:grafana_folder]
      expect(defn[:map_present]).to include(:uid)
      expect(defn[:map_present]).to include(:parent_folder_uid)
    end

    it 'defines expected outputs' do
      defn = described_class.resource_definitions[:grafana_folder]
      expect(defn[:outputs]).to include(id: :id, uid: :uid, url: :url)
    end
  end

  describe Pangea::Resources::GrafanaDataSource do
    it 'has resource definitions registered' do
      expect(described_class.resource_definitions).to have_key(:grafana_data_source)
    end

    it 'uses DataSourceAttributes for validation' do
      defn = described_class.resource_definitions[:grafana_data_source]
      expect(defn[:attributes_class]).to eq(Pangea::Resources::Grafana::Types::DataSourceAttributes)
    end

    it 'maps type, name, and url as required attributes' do
      defn = described_class.resource_definitions[:grafana_data_source]
      expect(defn[:map]).to include(:type, :name, :url)
    end

    it 'maps uid, json_data_encoded, secure_json_data_encoded as present-only' do
      defn = described_class.resource_definitions[:grafana_data_source]
      expect(defn[:map_present]).to include(:uid, :json_data_encoded, :secure_json_data_encoded)
    end

    it 'maps is_default as a boolean attribute' do
      defn = described_class.resource_definitions[:grafana_data_source]
      expect(defn[:map_bool]).to include(:is_default)
    end

    it 'defines expected outputs' do
      defn = described_class.resource_definitions[:grafana_data_source]
      expect(defn[:outputs]).to include(id: :id, uid: :uid)
    end
  end
end
