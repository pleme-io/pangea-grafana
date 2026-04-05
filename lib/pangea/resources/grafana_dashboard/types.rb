# frozen_string_literal: true
require 'dry-struct'

module Pangea::Resources::Grafana::Types
  class DashboardAttributes < Pangea::Resources::BaseAttributes
    transform_keys(&:to_sym)
    T = Pangea::Resources::Grafana::Types

    attribute :config_json, T::String
    attribute? :folder, T::String.optional
    attribute? :overwrite, T::Bool.optional
    attribute? :message, T::String.optional
  end
end
