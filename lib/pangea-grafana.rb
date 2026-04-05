# frozen_string_literal: true
require 'pangea-core'
require 'terraform-synthesizer'
require_relative 'pangea/types/grafana_types'
require_relative 'pangea/resources/grafana_dashboard/types'
require_relative 'pangea/resources/grafana_dashboard/resource'
require_relative 'pangea/resources/grafana_folder/types'
require_relative 'pangea/resources/grafana_folder/resource'
require_relative 'pangea/resources/grafana_data_source/types'
require_relative 'pangea/resources/grafana_data_source/resource'
require_relative 'pangea/resources/grafana'

# Dashboard Builder DSL
require_relative 'pangea/grafana/dashboard_builder'
