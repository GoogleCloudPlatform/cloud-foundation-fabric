# Network Monitoring Agent

This script is responsible for testing connectivity and writing custom metrics
on the monitoring project. This has been packed with terraform script
provisioning also the underlying GCP infrastructure and configuration
management, but it might be used as a standalone script.

<!-- TOC -->
* [Network Monitoring Agent](#network-monitoring-agent)
  * [Quick Usage Example](#quick-usage-example)
  * [Debugging and Troubleshooting](#debugging-and-troubleshooting)
<!-- TOC -->

## Quick Usage Example

The tool behaves like a regular CLI app, with several options documented via the
usual short help:

```text
./main.py --help

Usage: main.py [OPTIONS]

  CLI entry point.

Options:
  -p, --project TEXT            Target GCP project id for metrics.  [required]
  --endpoint <TEXT INTEGER>...  Endpoints to test as ip port whitespace
                                separated, this is a repeatable arg.
  --agent TEXT                  Agent VM running the script  [required]
  --debug                       Turn on debug logging.
  --interval INTEGER            Time interval between checks in seconds.
  --timeout INTEGER             Timeout waiting for connection to be
                                established.
  --help                        Show this message and exit.
```

In normal use three pieces of information need to be passed in:

- the monitoring project where metric descriptors and timeseries will be
  stored (project argument)
- one or more endpoints for connectivity to be tested (e.g.  '--endpoint "
  8.8.8.8" 53')
- the agent argument resulting in a label associated to the time series
  published by this agent

A typical invocation might look like this:

```bash
./main.py \
  --project my-net-project
  --endpoint "8.8.8.8" 53 --endpoint "8.8.4.4" 53
  --agent "test-vm"
```

## Debugging and Troubleshooting

Note that python version >= 3.10 is required.

If you run into a `ModuleNotFoundError`, install the required dependencies:
`pip3 install -r requirements.txt`
