# frozen_string_literal: true
require 'dry-struct'

module Pangea::Resources::Grafana::Types
  class FolderAttributes < Pangea::Resources::BaseAttributes
    transform_keys(&:to_sym)
    T = Pangea::Resources::Grafana::Types

    attribute :title, T::String
    attribute? :uid, T::String.optional
    attribute? :parent_folder_uid, T::String.optional
  end
end
