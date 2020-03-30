# Container Optimized OS modules

This set of modules creates specialized [cloud-config](https://cloud.google.com/container-optimized-os/docs/how-to/run-container-instance#starting_a_docker_container_via_cloud-config) configurations for [Container Optimized OS](https://cloud.google.com/container-optimized-os/docs), that are used to quickly spin up containerized services for DNS, HTTP, or databases.

It's meant to fullfill different use cases:

- when designing, to quickly prototype specialized services (eg MySQL access or HTTP serving)
- when planning migrations, to emulate production services for core infrastructure or perfomance testing
- in production, to easily add glue components for services like DNS (eg to work around inbound/outbound forwarding limitations)
- as a basis to implement cloud-native production deployments that leverage cloud-init for configuration management

## Available modules

### CoreDNS

- [ ] test module
- [ ] add description and examples here

### MySQL

- [ ] test module
- [ ] add description and examples here

### Nginx

- [ ] write module
- [ ] add description and examples here

### Squid forward proxy

- [ ] write module
- [ ] add description and examples here
