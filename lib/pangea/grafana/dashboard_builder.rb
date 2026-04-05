# frozen_string_literal: true

module Pangea
  module Grafana
    # DSL for building Grafana dashboard JSON.
    #
    # Usage:
    #   json = DashboardBuilder.build(title: "My Dashboard", uid: "my-dash") do |d|
    #     d.variable(:datasource, type: :datasource, query: "prometheus")
    #     d.row("Section") do |r|
    #       r.timeseries("Metric", unit: "bytes") do |p|
    #         p.query('up{job="app"}', legend: "{{instance}}")
    #       end
    #     end
    #   end
    class DashboardBuilder
      attr_reader :title, :uid, :tags, :description

      def initialize(title:, uid:, tags: [], description: "", time_from: "now-1h", time_to: "now")
        @title = title
        @uid = uid
        @tags = tags
        @description = description
        @time_from = time_from
        @time_to = time_to
        @panels = []
        @variables = []
        @next_id = 1
        @cursor_y = 0
      end

      def self.build(**kwargs, &block)
        builder = new(**kwargs)
        block&.call(builder)
        builder.to_json
      end

      def variable(name, type: :datasource, query: "prometheus", label: nil, hide: 0)
        @variables << Variable.new(name: name, type: type, query: query, label: label || name.to_s.capitalize, hide: hide)
      end

      def row(title, &block)
        # Add a row panel
        row_panel = {
          "id" => next_id!,
          "type" => "row",
          "title" => title,
          "gridPos" => { "h" => 1, "w" => 24, "x" => 0, "y" => @cursor_y },
          "collapsed" => false,
          "panels" => []
        }
        @panels << row_panel
        @cursor_y += 1

        row_ctx = RowContext.new(self)
        block&.call(row_ctx)
      end

      def timeseries(title, unit: nil, width: 12, height: 8, fill: 10, line_width: 2, &block)
        panel = Panel.new(
          type: "timeseries", title: title, unit: unit,
          width: width, height: height, fill: fill, line_width: line_width
        )
        block&.call(panel)
        add_panel(panel)
      end

      def stat(title, unit: nil, width: 6, height: 4, &block)
        panel = Panel.new(type: "stat", title: title, unit: unit, width: width, height: height)
        block&.call(panel)
        add_panel(panel)
      end

      def gauge(title, unit: nil, width: 6, height: 4, min: 0, max: nil, &block)
        panel = Panel.new(type: "gauge", title: title, unit: unit, width: width, height: height, min: min, max: max)
        block&.call(panel)
        add_panel(panel)
      end

      def table(title, width: 24, height: 8, &block)
        panel = Panel.new(type: "table", title: title, width: width, height: height)
        block&.call(panel)
        add_panel(panel)
      end

      def add_panel(panel)
        x = @panels.select { |p| p.is_a?(Hash) ? p["gridPos"]["y"] == @cursor_y : false }.size
        # Auto-wrap to next row if x would exceed 24
        col_x = 0
        same_row = @panels.select do |p|
          next false unless p.is_a?(Hash)
          p["gridPos"]["y"] == @cursor_y && p["type"] != "row"
        end
        col_x = same_row.sum { |p| p["gridPos"]["w"] }
        if col_x + panel.width > 24
          @cursor_y += panel.height
          col_x = 0
        end

        hash = panel.to_hash(next_id!, col_x, @cursor_y, "${datasource}")
        @panels << hash
        # Advance cursor_y if this panel fills the row
        if col_x + panel.width >= 24
          @cursor_y += panel.height
        end
      end

      def to_json
        require 'json'
        JSON.pretty_generate(to_hash)
      end

      def to_hash
        {
          "annotations" => { "list" => [] },
          "description" => @description,
          "editable" => true,
          "fiscalYearStartMonth" => 0,
          "graphTooltip" => 1,
          "id" => nil,
          "links" => [],
          "panels" => @panels.select { |p| p.is_a?(Hash) },
          "schemaVersion" => 39,
          "tags" => @tags,
          "templating" => { "list" => @variables.map(&:to_hash) },
          "time" => { "from" => @time_from, "to" => @time_to },
          "timepicker" => {},
          "timezone" => "utc",
          "title" => @title,
          "uid" => @uid,
          "version" => 1
        }
      end

      private

      def next_id!
        id = @next_id
        @next_id += 1
        id
      end
    end

    # Context for building panels within a row
    class RowContext
      def initialize(builder)
        @builder = builder
      end

      def timeseries(title, **opts, &block) = @builder.timeseries(title, **opts, &block)
      def stat(title, **opts, &block) = @builder.stat(title, **opts, &block)
      def gauge(title, **opts, &block) = @builder.gauge(title, **opts, &block)
      def table(title, **opts, &block) = @builder.table(title, **opts, &block)
    end

    # A single panel with queries
    class Panel
      attr_reader :type, :title, :unit, :width, :height, :queries, :thresholds

      def initialize(type:, title:, unit: nil, width: 12, height: 8, fill: 10, line_width: 2, min: nil, max: nil)
        @type = type
        @title = title
        @unit = unit
        @width = width
        @height = height
        @fill = fill
        @line_width = line_width
        @min = min
        @max = max
        @queries = []
        @thresholds = []
      end

      def query(expr, legend: "", ref_id: nil)
        ref_id ||= ("A".ord + @queries.size).chr
        @queries << Query.new(expr: expr, legend: legend, ref_id: ref_id)
      end

      def threshold(value, color:)
        @thresholds << { "color" => color, "value" => value }
      end

      def to_hash(id, x, y, datasource_var)
        h = {
          "id" => id,
          "title" => @title,
          "type" => @type,
          "gridPos" => { "h" => @height, "w" => @width, "x" => x, "y" => y },
          "datasource" => { "type" => "prometheus", "uid" => datasource_var },
          "targets" => @queries.map { |q| q.to_hash },
          "fieldConfig" => build_field_config,
        }
        h["options"] = build_options if %w[stat gauge].include?(@type)
        h
      end

      private

      def build_field_config
        defaults = {}
        defaults["unit"] = @unit if @unit
        defaults["min"] = @min if @min
        defaults["max"] = @max if @max

        if @type == "timeseries"
          defaults["custom"] = { "fillOpacity" => @fill, "lineWidth" => @line_width }
        end

        unless @thresholds.empty?
          defaults["thresholds"] = { "mode" => "absolute", "steps" => @thresholds }
        end

        { "defaults" => defaults }
      end

      def build_options
        case @type
        when "stat"
          { "reduceOptions" => { "calcs" => ["lastNotNull"] }, "textMode" => "auto" }
        when "gauge"
          { "reduceOptions" => { "calcs" => ["lastNotNull"] } }
        else
          {}
        end
      end
    end

    # A PromQL/LogQL query
    class Query
      attr_reader :expr, :legend, :ref_id

      def initialize(expr:, legend: "", ref_id: "A")
        @expr = expr
        @legend = legend
        @ref_id = ref_id
      end

      def to_hash
        { "expr" => @expr, "legendFormat" => @legend, "refId" => @ref_id }
      end
    end

    # A template variable
    class Variable
      def initialize(name:, type: :datasource, query: "prometheus", label: "Data Source", hide: 0)
        @name = name.to_s
        @type = type.to_s
        @query = query
        @label = label
        @hide = hide
      end

      def to_hash
        h = {
          "name" => @name,
          "label" => @label,
          "type" => @type,
          "hide" => @hide,
        }
        case @type
        when "datasource"
          h["query"] = @query
          h["refresh"] = 1
          h["includeAll"] = false
          h["multi"] = false
        when "query"
          h["datasource"] = { "type" => "prometheus", "uid" => "${datasource}" }
          h["query"] = @query
          h["refresh"] = 2
          h["sort"] = 1
        end
        h
      end
    end
  end
end
