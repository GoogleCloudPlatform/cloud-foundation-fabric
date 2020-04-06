# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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

[Unreleased]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.0.0...HEAD
[1.2.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.1...v1.2
[1.1.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.0...v1.1
[1.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v0.1...v1.0
