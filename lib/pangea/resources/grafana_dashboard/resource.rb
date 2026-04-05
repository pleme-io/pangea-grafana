# frozen_string_literal: true

module Pangea::Resources
  module GrafanaDashboard
    include Pangea::Resources::ResourceBuilder

    define_resource :grafana_dashboard,
      attributes_class: Grafana::Types::DashboardAttributes,
      outputs: { id: :id, uid: :uid, url: :url, version: :version, slug: :slug },
      map: [:config_json],
      map_present: [:folder, :message],
      map_bool: [:overwrite]
  end
end
