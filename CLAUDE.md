# pangea-grafana -- Grafana provider for Pangea DSL

Ruby gem providing 3 typed Grafana resource functions for the
Pangea infrastructure DSL. Provides Dry::Struct validation for
dashboards, folders, and data sources.

## Build

```bash
bundle install
bundle exec rspec   # unit tests
bundle exec rake    # default task
```

## Architecture

```
lib/
  pangea-grafana.rb               # Gem entry point
  pangea-grafana/
    version.rb                   # PangeaGrafana::VERSION
  pangea/
    resources/
      grafana.rb                 # Provider registration
      grafana_dashboard/         # GrafanaDashboard resource
      grafana_folder/            # GrafanaFolder resource
      grafana_data_source/       # GrafanaDataSource resource
    types/
      grafana_types.rb           # Dry::Types module for Grafana
```

## Resources

| Resource | Required Attributes | Optional Attributes |
|----------|-------------------|-------------------|
| `grafana_dashboard` | config_json | folder, overwrite, message |
| `grafana_folder` | title | uid, parent_folder_uid |
| `grafana_data_source` | type, name, url | uid, is_default, json_data_encoded, secure_json_data_encoded |

## Key Types

Each resource is a `Dry::Struct` subclass with typed attributes.
Used as: `Pangea::Resources::Grafana.grafana_dashboard(name: ..., ...)`.

## Testing

```bash
bundle exec rspec
```

## Dependencies

pangea-core ~> 0.2, terraform-synthesizer ~> 0.0.28, dry-types ~> 1.7,
dry-struct ~> 1.6. Ruby >= 3.3, Apache-2.0.
