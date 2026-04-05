# frozen_string_literal: true

module Pangea::Resources
  module GrafanaFolder
    include Pangea::Resources::ResourceBuilder

    define_resource :grafana_folder,
      attributes_class: Grafana::Types::FolderAttributes,
      outputs: { id: :id, uid: :uid, url: :url },
      map: [:title],
      map_present: [:uid, :parent_folder_uid]
  end
end
