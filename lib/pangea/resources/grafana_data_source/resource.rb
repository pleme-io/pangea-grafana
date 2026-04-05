# frozen_string_literal: true

module Pangea::Resources
  module GrafanaDataSource
    include Pangea::Resources::ResourceBuilder

    define_resource :grafana_data_source,
      attributes_class: Grafana::Types::DataSourceAttributes,
      outputs: { id: :id, uid: :uid },
      map: [:type, :name, :url],
      map_present: [:uid, :json_data_encoded, :secure_json_data_encoded],
      map_bool: [:is_default]
  end
end
