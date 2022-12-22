# Network Dashboard Discovery Tool

This tool constitutes the discovery and data gathering side of the Network Dashboard, and can be used in combination with the related [Terraform deployment examples](../), or packaged in different ways including standalone manual use.

- [Quick Usage Example](#quick-usage-example)
- [High Level Architecture and Plugin Design](#high-level-architecture-and-plugin-design)
- [Debugging and Troubleshooting](#debugging-and-troubleshooting)

## Quick Usage Example

The tool behaves like a regular CLI app, with several options documented via the usual short help:

```text
./main.py --help

Usage: main.py [OPTIONS]

  CLI entry point.

Options:
  -dr, --discovery-root TEXT        Root node for asset discovery,
                                    organizations/nnn or folders/nnn.  [required]
  -mon, --monitoring-project TEXT   GCP monitoring project where metrics will be
                                    stored.  [required]
  -p, --project TEXT                GCP project id to be monitored, can be specified multiple
                                    times.
  -f, --folder INTEGER              GCP folder id to be monitored, can be specified multiple
                                    times.
  --custom-quota-file FILENAME      Custom quota file in yaml format.
  --dump-file FILENAME              Export JSON representation of resources to
                                    file.
  --load-file FILENAME              Load JSON resources from file, skips init and
                                    discovery.
  --debug-plugin TEXT               Run only core and specified timeseries plugin.
  --help                            Show this message and exit.
```

In normal use three pieces of information need to be passed in:

- the monitoring project where metric descriptors and timeseries will be stored
- the discovery root scope (organization or top-level folder, [see here for examples](../deploy-cloud-function/README.md#discovery-configuration))
- the list of folders and/or projects that contain the resources to be monitored (folders will discover all included projects)

To account for custom quota which are not yet exposed via API or which are applied to individual networks, a YAML file with quota overrides can be specified via the `--custom-quota-file` option. Refer to the [included sample](./custom-quotas.sample) for details on its format.

A typical invocation might look like this:

```bash
./main.py \
  -dr organizations/1234567890 \
  -op my-monitoring-project \
  --folder 1234567890 --folder 987654321 \
  --project my-net-project \
  --custom-quota-file custom-quotas.yaml
```

## High Level Architecture and Plugin Design

The tool is composed of two main processing phases

- the discovery of resources within a predefined scope using Cloud Asset Inventory and Compute APIs
- the computation of metric timeseries derived from discovered resources

Once both phases are complete, the tool sends generated timeseries to Cloud Operations together with any missing metric descriptors.

Every action during those phases is delegated to a series of plugins, which conform to simple interfaces and exchange predefined basic types with the main module. Plugins are registered at runtime, and are split in broad categories depending on the stage where they execute:

- init plugin functions have the task of preparing the required keys in the shared resource data structure. Usually, init functions are usually small and there's one for each discovery plugin
- discovery plugin functions do the bulk of the work of discovering resources; they return HTTP Requests (e.g. calls to GCP APIs) or Resource objects (extracted from the API responses) to the main module, and receive HTTP Responses
- timeseries plugin read from the shared resource data structure, and return computed Metric Descriptors and Timeseries objects

Plugins are registered via simple functions defined in the [plugin package initialization file](./plugins/__init__.py), and leverage [utility functions](./plugins/utils.py) for batching API requests and parsing results.

The main module cycles through stages, calling stage plugins in succession iterating over their results.

## Debugging and Troubleshooting

Note that python version > 3.8 is required.

If you run into a `ModuleNotFoundError`, install the required dependencies:
`pip3 install -r requirements.txt`

A few convenience options are provided to simplify development, debugging and troubleshooting:

- the discovery phase results can be dumped to a JSON file, that can then be used to check actual resource representation, or skip the discovery phase entirely to speed up development of timeseries-related functions
- a single timeseries plugin can be optionally run alone, to focus debugging and decrease the amount of noise from logs and outputs

This is an example call that stores discovery results to a file:

```bash
./main.py \
  -dr organizations/1234567890 \
  -op my-monitoring-project \
  --folder 1234567890 --folder 987654321 \
  --project my-net-project \
  --custom-quota-file custom-quotas.yaml \
  --dump-file out.json
```

And this is the corresponding call that skips the discovery phase and also runs a single timeseries plugin:

```bash
./main.py \
  -dr organizations/1234567890 \
  -op my-monitoring-project \
  --folder 1234567890 --folder 987654321 \
  --project my-net-project \
  --custom-quota-file custom-quotas.yaml \
  --load-file out.json \
  --debug-plugin plugins.series-firewall-rules.timeseries
```
