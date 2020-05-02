# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

- **incompatible change** the `bigquery` module has been removed and replaced by the new `bigquery-dataset` module

## [1.4.1] - 2020-05-02

- new `secret-manager` module
- fix access in `bigquery` module, this is the last version of this module to support multiple datasets, future versions will be called `bigquery-dataset`

## [1.4.0] - 2020-05-01

- fix DNS module internal zone lookup
- fix Cloud NAT module internal router name lookup
- re-enable and update outputs for the foundations environments example
- add peering route configuration for private clusters to GKE cluster module
- **incompatible changes** in the GKE nodepool module
  - rename `node_config_workload_metadata_config` variable to `workload_metadata_config`
  - new default for `workload_metadata_config` is `GKE_METADATA_SERVER`
- **incompatible change** in the `compute-vm` module
  - removed support for MIG and the `group_manager` variable
- add `compute-mig` and `net-ilb` modules
- **incompatible change** in `net-vpc`
  - a new `name` attribute has been added to the `subnets` variable, allowing to directly set subnet name, to update to the new module add an extra `name = false` attribute to each subnet

## [1.3.0] - 2020-04-08

- add organization policy module
- add support for organization policies to folders and project modules

## [1.2.0] - 2020-04-06

- add squid container to the `cloud-config-container` module

## [1.1.0] - 2020-03-27

- rename the `cos-container` suite of modules to `cloud-config-container`
- refactor the `onprem-in-a-box` module to only manage the `cloud-config` configuration, and make it part of the `cloud-config-container` suite of modules
- update the `onprem-google-access-dns` example to use the refactored `onprem` module
- fix the `external_addresses` output in the `compute-vm` module
- small tweaks and fixes to the `cloud-config-container` modules

## [1.0.0] - 2020-03-27

- merge development branch with suite of new modules and end-to-end examples

[Unreleased]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.4.1...HEAD
[1.4.1]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.2...v1.3.0
[1.2.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.1...v1.2
[1.1.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.0...v1.1
[1.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v0.1...v1.0
