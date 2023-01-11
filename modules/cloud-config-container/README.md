# Instance Configuration via `cloud-config`

This set of modules creates specialized [cloud-config](https://cloud.google.com/container-optimized-os/docs/how-to/run-container-instance#starting_a_docker_container_via_cloud-config) configurations, which are designed for use with [Container Optimized OS](https://cloud.google.com/container-optimized-os/docs) (the onprem module is the only exception) but can also be used as a basis for other image types or cloud providers.

These modules are designed for several use cases:

- to quickly prototype specialized services (eg MySQL access or HTTP serving) for prototyping infrastructure
- to emulate production services for perfomance testing
- to easily add glue components for services like DNS (eg to work around inbound/outbound forwarding limitations)
- to implement cloud-native production deployments that leverage cloud-init for configuration management, without the need of a separate tool

## Available modules

- [CoreDNS](./coredns)
- [MySQL](./mysql)
- [Nginx](./nginx)
- [Squid forward proxy](./squid)
- On-prem in Docker (*needs fixing*)

## Using the modules

All modules are designed to be as lightweight as possible, so that specialized modules like [compute-vm](../compute-vm) can be leveraged to manage instances or instance templates, and to allow simple forking to create custom derivatives.

To use the modules with instances or instance templates, simply set use their `cloud_config` output for the `user-data` metadata. When updating the metadata after a variable change remember to manually restart the instances that use a module's output, or the changes won't effect the running system.

## TODO

- [ ] convert all `xxx_config` variables to use file content instead of path
