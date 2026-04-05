# frozen_string_literal: true

module Pangea::Resources
  module Grafana
    include GrafanaDashboard
    include GrafanaFolder
    include GrafanaDataSource
  end
end
Pangea::ResourceRegistry.register_module(Pangea::Resources::Grafana)
