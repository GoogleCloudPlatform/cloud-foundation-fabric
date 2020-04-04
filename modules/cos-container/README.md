# Container Optimized OS modules

This set of modules creates specialized [cloud-config](https://cloud.google.com/container-optimized-os/docs/how-to/run-container-instance#starting_a_docker_container_via_cloud-config) configurations for [Container Optimized OS](https://cloud.google.com/container-optimized-os/docs), that are used to quickly spin up containerized services for DNS, HTTP, or databases.

It's meant to fullfill different use cases:

- when designing, to quickly prototype specialized services (eg MySQL access or HTTP serving)
- when planning migrations, to emulate production services for core infrastructure or perfomance testing
- in production, to easily add glue components for services like DNS (eg to work around inbound/outbound forwarding limitations)
- as a basis to implement cloud-native production deployments that leverage cloud-init for configuration management

## Available modules

- [CoreDNS](./coredns)
- [MySQL](./mysql)
- [On-prem in Docker](./onprem)
- [ ] Nginx
- [ ] Squid forward proxy

## Using the modules

All modules are designed to be as lightweight as possible, so that specialized modules like [compute-vm](../compute-vm) can be leveraged to manage instances or instance templates, and to allow simple forking to create custom derivatives.

To use the modules with instances or instance templates, simply set use their `cloud_config` output for the `user-data` metadata. When updating the metadata after a variable change remember to manually restart the instances that use a module's output, or the changes won't effect the running system.

For convenience when developing or prototyping infrastructure, an optional test instance is included in all modules. If it's not needed, the linked `*instance.tf` files can be removed from the modules without harm.
