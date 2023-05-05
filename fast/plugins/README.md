# FAST plugin system

This folders details a simple mechanism that can be used to add extra functionality to FAST stages, and a few examples that implement simple plugins that can be used as-is.

## Available plugins

### Networking

- [Serverless VPC Access Connector](./2-networking-serverless-connector/)

## Anatomy of a plugin

FAST plugins are much simpler and easier to code than full-blown stages: each plugin is meant to add a single feature using a small set of resources, and interacting directly with stage modules and variables.

A simple plugin might be composed of a single file with one resource, and grow up to the canonical set of one "main" (resources), one variables, and outputs file.

Plugin file names start with the `local-` prefix which is purposefully excluded in FAST stages via Git ignore, so that plugins are not accidentally committed to stages during development and staying aligned with our master branch is possible.

Plugins are structured here as individual folders, organized in top-level folders according to the FAST stage they are designed to work with.

As an example, the [`2-networking/serverless-connector` plugin](./2-networking-serverless-connector/) implements centralized [Serverless VPC Access Connectors](https://cloud.google.com/vpc/docs/serverless-vpc-access) for our networking stages, and is composed of three files:

- [`local-serverless-connector.tf`](./2-networking-serverless-connector/local-serverless-connector.tf) managing resources including the subnets needed in each VPC and the connectors themselves
- [`local-serverless-connector-outputs.tf`](./2-networking-serverless-connector/local-serverless-connector-outputs.tf) defining a single `serverless_connectors` output for the plugin, and optional output files
- [`local-serverless-connector-variables.tf`](./2-networking-serverless-connector/local-serverless-connector-variables.tf) defining a single `serverless_connector_config` variable used to configure the plugin
