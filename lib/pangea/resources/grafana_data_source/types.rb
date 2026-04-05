# frozen_string_literal: true
require 'dry-struct'

module Pangea::Resources::Grafana::Types
  class DataSourceAttributes < Pangea::Resources::BaseAttributes
    transform_keys(&:to_sym)
    T = Pangea::Resources::Grafana::Types

    attribute :type, T::String
    attribute :name, T::String
    attribute :url, T::String
    attribute? :uid, T::String.optional
    attribute? :is_default, T::Bool.optional
    attribute? :json_data_encoded, T::String.optional
    attribute? :secure_json_data_encoded, T::String.optional
  end
end
