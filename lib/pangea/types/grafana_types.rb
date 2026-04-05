# frozen_string_literal: true
require 'dry-types'

module Pangea
  module Resources
    module Grafana
      module Types
        include Dry.Types()
        T = Pangea::Resources::Types
        DashboardLayoutType = T::String.constrained(included_in: %w[ordered free])
        DatasourceType = T::String.constrained(included_in: %w[prometheus loki tempo graphite elasticsearch influxdb mysql postgres])
      end
    end
  end
end
