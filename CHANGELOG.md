# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

- fix permadiff in `net-vpc-firewall` module rules
- new [gke-hub](modules/gke-hub) module
- new [unmanaged-instances-healthcheck](examples/cloud-operations/unmanaged-instances-healthcheck) example
- add support for IAM to `data-catalog-policy-tag` module
- add support for IAM additive to `folder` module, fixes #580
- **incompatible change** the variable for PSA ranges in the `net-vpc` module has changed to support configuring peering routes
- optionally turn off gcplogs driver in COS modules

**FAST**

- new [02-networking-peering](fast/stages/02-networking-peering) networking stage
- **incompatible change** the variable for PSA ranges in networking stages have changed

## [14.0.0] - 2022-02-25

- **incompatible change** removed `iam` key from logging sink configuration in the `project` and `organization` modules
- remove GCS to BQ with Dataflow example, replace by GCS to BQ with least privileges
- the `net-vpc` and `project` modules now use the beta provider for shared VPC-related resources
- new [iot-core](modules/iot-core) module
- **incompatible change** the variables for host and service Shared VPCs have changed in the project module
- **incompatible change** the variable for service identities IAM has changed in the project factory
- add `data-catalog-policy-tag` module
- new [workload identity federetion example](examples/cloud-operations/workload-identity-federation)
- new `api-gateway` [module](/modules/api-gateway) and [example](examples/serverless/api-gateway).
- **incompatible change** the `psn_ranges` variable has been renamed to `psa_ranges` in the `net-vpc` module and its type changed from `list(string)` to `map(string)`
- **incompatible change** removed `iam` flag for organization and folder level sinks
- **incompatible change** removed `ingress_settings` configuration option in the `cloud-functions` module.
- new [m4ce VM example](examples/cloud-operations/vm-migration/)
- Support for resource management tags in the `organization`, `folder`, `project`, `compute-vm`, and `kms` modules

**FAST**
- new [data platform](fast/stages/03-data-platform) stage 3
- new [02-networking-nva](fast/stages/02-networking-nva) networking stage
- allow customizing the names of custom roles
- added `environment` and `context` resource management tags
- use resource management tags to restrict scope of roles/orgpolicy.policyAdmin
- use `xpnServiceAdmin` (custom role) for stage 3 service accounts that need to attach to a shared VPC
- simplify and standarize ourputs from each stage
- standarize names of projects, service accounts and buckets
- swtich to folder-level `xpnAdmin` and `xpnServiceAdmin`
- moved networking projects to folder matching their enviroments


## [13.0.0] - 2022-01-27

- **initial Fabric Fast implementation**
- new `net-glb` module for Global External Load balancer
- new `project-factory` module in [`examples/factories`](./examples/factories)
- add missing service identity accounts (artifactregistry, composer) in project module
- new "Cloud Storage to Bigquery with Cloud Dataflow with least privileges" example
- support service dependencies for crypto key bindings in project module
- refactor project module in multiple files
- add support for per-file option overrides to tfdoc

## [12.0.0] - 2022-01-11

- new repo structure. All end-to-end examples moved to the top level `examples` folder

## [11.2.0] - 2022-01-11

- fix `net-vpc` subnet factory bug preventing the use of yamls with different shapes

## [11.1.0] - 2022-01-11

- add support for additive IAM bindings to `kms` module

## [11.0.0] - 2022-01-04

- **incompatible change** remove location from `gcs` bucket names
- add support for interpolating access levels based on keys to the `vpc-sc` module

## [10.0.1] - 2022-01-03

- remove lifecycle block from vpc sc perimeter resources

## [10.0.0] - 2021-12-31

- fix cases where bridge perimeter status resources are `null` in `vpc-sc` module
- re-release 9.0.3 as a major release as it contains breaking changes
  - update hierarchical firewall resources to use the newer `google_compute_firewall_*` resources
  - **incompatible change** rename `firewall_policy_attachments` to `firewall_policy_association` in the `organization` and `folder` modules
  - **incompatible change** updated API for the `net-vpc-sc` module

## [9.0.3] - 2021-12-31

- update hierarchical firewall resources to use the newer `google_compute_firewall_*` resources
- **incompatible change** rename `firewall_policy_attachments` to `firewall_policy_association` in the `organization` and `folder` modules
- **incompatible change** updated API for the `net-vpc-sc` module

## [9.0.2] - 2021-12-22

- ignore description changes in firewall policy rule to avoid permadiff, add factory example to `folder` module documentation

## [9.0.0] - 2021-12-22

- new `cloud-run` module
- added gVNIC support to `compute-vm` module
- added a rule factory to `net-vpc-firewall` module
- added a subnet factory to `net-vpc` module
- **incompatible change** added support for partitioned tables to `organization` module sinks 
- **incompatible change** renamed `private_service_networking_range` variable to `psc_ranges` in `net-vpc`module, and changed its type to `list(string)`
- added a firewall policy factory to `organization` and `firewall` module
- refactored `tfdoc`
- added support for metric scopes to the `project` module

## [8.0.0] - 2021-10-21

- added support for GCS notifications in `gcs` module
- added new `skip_delete` variable to `compute-vm` module
- **incompatible change** all modules and examples now require Terraform >= 1.0.0 and Google provider >= 4.0.0

## [7.0.0] - 2021-10-21

- new cloud operations example showing how to deploy infrastructure for [Compute Engine image builder based on Hashicorp Packer](./examples/cloud-operations/packer-image-builder)
- **incompatible change** the format of the `records` variable in the `dns` module has changed, to better support dynamic values
- new `naming-convention` module
- new `cloudsql-instance` module
- added support for website to `gcs` module, and removed auto-set labels
- new `factories` top-level folder with initial `subnets`, `firewall-hierarchical-policies`, `firewall-vpc-rules` and `example-environments` examples
- added new `description` variable to `compute-vm` module
- added support for L7 ILB subnets to `net-vpc` module
- added support to override default description in `compute-vm`
- added support for backup retention count in `cloudsql-instance`
- added new `description` variable to `cloud-function` module
- added new `description` variable to `bigquery-dataset` module
- added new `description` variable to `iam-service-account` module
- **incompatible change** fix deprecated message from `gke-nodepool`, change your `workload_metadata_config` to correct values (`GCE_METADATA` or `GKE_METADATA`)
- **incompatible change** changed maintenance window definition from `maintenance_start_time` to `maintenance_config` in `gke-cluster`
- added `monitoring_config`,`logging_config`, `dns_config` and `enable_l4_ilb_subsetting` to `gke-cluster`


## [6.0.0] - 2021-10-04

- new `apigee-organization` and `apigee-x-instance`
- generate `email` and `iam_email` statically in the `iam-service-account` module 
- new `billing-budget` module
- fix `scheduled-asset-inventory-export-bq` module
- output custom role information from the `organization` module
- enable multiple `vpc-sc` perimeters over multiple modules
- new cloud operations example showing how to [restrict service usage using delegated role grants](./examples/cloud-operations/iam-delegated-role-grants)
- **incompatible change** multiple instance support has been removed from the `compute-vm` module, to bring its interface in line with other modules and enable simple use of `for_each` at the module level; its variables have also slightly changed (`attached_disks`, `boot_disk_delete`, `crate_template`, `zone`)
- **incompatible change** dropped the `admin_ranges_enabled` variable in `net-vpc-firewall`. Set `admin_ranges = []` to get the same effect
- added the `named_ranges` variable to `net-vpc-firewall`

## [5.1.0] - 2021-08-30

- add support for `lifecycle_rule` in gcs module
- create `pubsub` service identity if service is enabled
- support for creation of GKE Autopilot clusters
- add support for CMEK keys in Data Foundation end to end example
- add support for VPC-SC perimeters in Data Foundation end to end example
- fix `vpc-sc` module
- new networking example showing how to use [Private Service Connect to call a Cloud Function from on-premises](./examples/networking/private-cloud-function-from-onprem/)
- new networking example showing how to organize [decentralized firewall](./examples/networking/decentralized-firewall/) management on GCP

## [5.0.0] - 2021-06-17

- fix `message_retention_duration` variable type in `pubsub` module
- move `bq` robot service account into the robot service account project output
- add IAM cryptDecrypt role to robot service account on specified keys
- add Service Identity creation on `project` module if secretmanager enabled
- add Data Foundation end to end example

## [4.9.0] - 2021-06-04

- **incompatible change** updated resource name for `google_dns_policy` on the `net-vpc` module
- added support for VPC-SC Ingress Egress policies on the `vpc-sc` module
- update CI to Terraform 0.15 and fix minor incompatibilities
- add `deletion_protection` to the `bigquery-dataset` module
- add support for dataplane v2 to GKE cluster module
- add BGP peer outputs to HA VPN module

## [4.8.0] - 2021-05-12

- added support for `CORS` to the `gcs` module
- make cluster creation optional in the Shared VPC example
- make service account creation optional in `iam-service-account` module
- new `third-party-solutions` top-level folder with initial `openshift` example
- added support for DNS Policies to the `net-vpc` module

## [4.7.0] - 2021-04-21

- **incompatible change** add support for `master_global_access_config` block in gke-cluster module
- add support for group-based IAM to resource management modules
- add support for private service connect

## [4.6.1] - 2021-04-01

- **incompatible change** support one group per zone in the `compute-vm` module
  the `group` output is now renamed to `groups`

## [4.6.0] - 2021-03-31

- **incompatible change** logging sinks now create non-authoritative bindings when iam=true
- fixed IAM bindings for module `bigquery` not specifying project_id
- remove device_policy from `vpc_sc` module as it requires BeyondCorp Enterprise Premium
- allow using unsuffixed name in `compute_vm` module

## [4.5.1] - 2021-03-27

- allow creating private DNS zones with no visible VPCs in `dns` module

## [4.5.0] - 2021-03-20

- new `logging-bucket` module to create Cloud Logging Buckets
- add support to create logging sinks using logging buckets as the destination
- **incompatible change** extended logging sinks to support per-sink exclusions
- new `net-vpc-firewall-yaml` module
- add support for regions, device policy and access policy dependency to `vpc-sc` module
- add support for joining VPC-SC perimeters in `project` module
- add `userinfo.email` to default scopes in `compute-vm` module

## [4.4.2] - 2021-03-05

- fix versions constraints on modules to avoid the `no available releases match the given constraints` error

## [4.4.1] - 2021-03-05

- depend specific org module resources (eg policies) from IAM bindings
- set version for google-beta provider in project module

## [4.4.0] - 2021-03-02

- new `filtering_proxy` networking example
- add support for a second region in the onprem networking example
- add support for per-tunnel router to VPN HA and VPN dynamic modules
- **incompatible change** the `attached_disks` variable type has changed in the `compute-vm` module, to add support for regional persistent disks, and attaching existing disks to instances / templates
- the hub and spoke via peering example now supports project creation, resource prefix, and GKE peering configuration
- make the `project_id` output from the `project` module non-dynamic. This means you can use this output as a key for map fed into a `for_each` (for example, as a key for `iam_project_bindings` in the `iam-service-accounts` module)
- add support for essential contacts in the in the `project`, `folder` and `organization` modules

## [4.3.0] - 2021-01-11

- new DNS for Shared VPC example
- **incompatible change** removed the `logging-sinks` module. Logging sinks can now be created the `logging_sinks` variable in the in the `project`, `folder` and `organization` modules
- add support for creating logging exclusions in the `project`, `folder` and `organization` modules
- add support for Confidential Compute to `compute-vm` module
- add support for handling IAM policy (bindings, audit config) as fully authoritative in the `organization` module

## [4.2.0] - 2020-11-25

- **incompatible change** the `org_id` variable and output in the `vpc-sc` module have been renamed to `organization_id`, the variable now accepts values in `organizations/nnnnnnnn` format
- **incompatible change** the `forwarders` variable in the `dns` module has a different type, to support specifying forwarding path
- add support for MTU in `net-vpc` module
- **incompatible change** access variables have been renamed in the `bigquery-dataset` module
- add support for IAM to the `bigquery-dataset` module
- fix default OAuth scopes in `gke-nodepool` module
- add support for hierarchical firewalls to the `folder` and `organization` modules
- **incompatible change** the `org_id` variable and output in the `organization` module have been renamed to `organization_id`, the variable now accepts values in `organizations/nnnnnnnn` format

## [4.1.0] - 2020-11-16

- **incompatible change** rename prefix for node configuration variables in `gke-nodepool` module [#156]
- add support for internally managed service account in `gke-nodepool` module [#156]
- made examples in READMEs runnable and testable [#157]
- **incompatible change** `iam_additive` is now keyed by role to be more resilient with dynamic values, a new `iam_additive_members` variable has been added for backwards compatibility.
- add support for node taints in `gke-nodepool` module
- add support for CMEK in `gke-nodepool` module

## [4.0.0] - 2020-11-06

- This is a major refactor adding support for Terraform 0.13 features
- **incompatible change** minimum required terraform version is now 0.13.0
- **incompatible change** `folders` module renamed to `folder`
- **incompatible change** `iam-service-accounts` module renamed to `iam-service-account`
- **incompatible change** all `iam_roles` and `iam_member` variables merged into a single `iam` variable. This change affects most modules
- **incompatible change** modules like `folder`, `gcs`, `iam-service-account` now create a single resource. Use for_each at the module level if you need multiple instances
- added basic variable validations to some modules

## [3.5.0] - 2020-10-27

- end to end example for scheduled Cloud Asset Inventory export to Bigquery
- decouple Cloud Run from Istio in GKE cluster module
- depend views on tables in bigquery dataset module
- bring back logging options for firewall rules in `net-vpc-firewall` module
- removed interpolation-only expressions causing terraform warnings
- **incompatible change** simplify alias IP specification in `compute-vm`. We now use a map (alias range name to list of IPs) instead of a list of maps.
- allow using alias IPs with `instance_count` in `compute-vm`
- add support for virtual displays in `compute-vm`
- add examples of alias IPs in `compute-vm` module
- fix support for creating disks from images in `compute-vm`
- allow creating single-sided peerings in `net-vpc` and `net-vpc-peering`
- use service project registration to Shared VPC in GKE example to remove need for two-step apply

## [3.4.0] - 2020-09-24

- add support for logging and better type for the `retention_policies` variable in `gcs` module
- **incompatible change** deprecate `bucket_policy_only` in favor of `uniform_bucket_level_access` in `gcs` module
- **incompatible change** allow project module to configure itself as both shared VPC service and host project

## [3.3.0] - 2020-09-01

- remove extra readers in `gcs-to-bq-with-dataflow` example (issue: 128)
- make VPC creation optional in `net-vpc` module to allow managing a pre-existing VPC
- make HA VPN gateway creation optional in `net-vpn-ha` module
- add retention_policy in `gcs` module
- refactor `net-address` module variables, and add support for internal address `purpose`

## [3.2.0] - 2020-08-29

- **incompatible change** add alias IP support in `cloud-vm` module
- add tests for `data-solutions` examples
- fix apply errors on dynamic resources in dataflow example
- make zone creation optional in `dns` module
- new `quota-monitoring` end-to-end example in `cloud-operations`

## [3.1.1] - 2020-08-26

- fix error in `project` module

- **incompatible change** make HA VPN Gateway creation optional for `net-vpn-ha` module. Now an existing HA VPN Gateway can be used. Updating to the new version of the module will cause VPN Gateway recreation which can be handled by `terraform state rm/terraform import` operations.  

## [3.1.0] - 2020-08-16

- **incompatible change** add support for specifying a different project id in the GKE cluster module; if using the `peering_config` variable, `peering_config.project_id` now needs to be explicitly set, a `null` value will reuse the `project_id` variable for the peering

## [3.0.0] - 2020-08-15

- **incompatible change** the top-level `infrastructure` folder has been renamed to `networking`
- add end-to-end example for ILB as next hop
- add basic tests for `foundations` and `networking` end-to-end examples
- fix Shared VPC end-to-end example and documentation

## [2.8.0] - 2020-08-01

- fine-grained Cloud DNS IAM via Service Directory example
- add feed id output dependency on IAM roles in `pubsub` module

## [2.7.1] - 2020-07-24

- fix provider issue in bigquery module

## [2.7.0] - 2020-07-24

- add support for VPC connector and ingress settings to `cloud-function` module
- add support for logging to `net-cloudnat` module

## [2.6.0] - 2020-07-19

- **incompatible changes** setting zone in the `compute-vm` module is now done via an optional `zones` variable, that accepts a list of zones
- fix optional IAM permissions in folder unit module

## [2.5.0] - 2020-07-10

- new `vpc-sc` module
- add support for Shared VPC to the `project` module
- fix bug with `compute-vm` address reservations introduced in [2.4.1]

## [2.4.2] - 2020-07-09

- add support for Shielded VM to `compute-vm`

## [2.4.1] - 2020-07-06

- better fix external IP assignment in `compute-vm`

## [2.4.0] - 2020-07-06

- fix external IP assignment in `compute-vm`
- new top-level `cloud-operations` example folder
- Cloud Asset Inventory end to end example in `cloud-operations`

## [2.3.0] - 2020-07-02

- new 'Cloud Storage to Bigquery with Cloud Dataflow' end to end data solution
- **incompatible change** additive IAM bindings are now keyed by identity instead of role, and use a single `iam_additive_bindings` variable, refer to [#103] for details
- set `delete_contents_on_destroy` in the foundations examples audit dataset to allow destroying
- trap errors raised by the `project` module on destroy

## [2.2.0] - 2020-06-29

- make project creation optional in `project` module to allow managing a pre-existing project
- new `cloud-endpoints` module
- new `cloud-function` module

## [2.1.0] - 2020-06-22

- **incompatible change** routes in the `net-vpc` module now interpolate the VPC name to ensure uniqueness, upgrading from a previous version will drop and recreate routes
- the top-level `docker-images` folder has been moved inside `modules/cloud-config-container/onprem`
- `dns_keys` output added to the `dns` module
- add `group-config` variable, `groups` and `group_self_links` outputs to `net-ilb` module to allow creating ILBs for externally managed instances
- make the IAM bindings depend on the compute instance in the `compute-vm` module

## [2.0.0] - 2020-06-11

- new `data-solutions` section and `cmek-via-centralized-kms` example
- **incompatible change** static VPN routes now interpolate the VPN gateway name to enforce uniqueness, upgrading from a previous version will drop and recreate routes

## [1.9.0] - 2020-06-10

- new `bigtable-instance` module
- add support for IAM bindings to `compute-vm` module

## [1.8.1] - 2020-06-07

- use `all` instead of specifying protocols in the admin firewall rule of the `net-vpc-firewall` module
- add support for encryption keys in `gcs` module
- set `next_hop_instance_zone` in `net-vpc` for next hop instance routes to avoid triggering recreation

## [1.8.0] - 2020-06-03

- **incompatible change** the `kms` module has been refactored and will be incompatible with previous state
- **incompatible change** robot and default service accounts outputs in the `project` module have been refactored and are now exposed via a single `service_account` output (cf [#82])
- add support for PD CSI driver in GKE module
- refactor `iam-service-accounts` module outputs to be more resilient
- add option to use private GCR to `cos-generic-metadata` module

## [1.7.0] - 2020-05-30

- add support for disk encryption to the `compute-vm` module
- new `datafusion` module
- new `container-registry` module
- new `artifact-registry` module

## [1.6.0] - 2020-05-20

- add output to `gke-cluster` exposing the cluster's CA certificate
- fix `gke-cluster` autoscaling options
- add support for Service Directory bound zones to the `dns` module
- new `service-directory` module
- new `source-repository` module

## [1.5.0] - 2020-05-11

- **incompatible change** the `bigquery` module has been removed and replaced by the new `bigquery-dataset` module
- **incompatible change** subnets in the `net-vpc` modules are now passed as a list instead of map, and all related variables for IAM and flow logs use `region/name` instead of `name` keys; it's now possible to have the same subnet name in different regions
- replace all references to the removed `resourceviews.googleapis.com` API with `container.googleapis.com`
- fix advanced options in `gke-nodepool` module
- fix health checks in `compute-mig` and `net-ilb` modules
- new `cos-generic-metadata` module in the `cloud-config-container` suite
- new `envoy-traffic-director` module in the `cloud-config-container` suite
- new `pubsub` module


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

<!-- markdown-link-check-disable -->
[Unreleased]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v14.0.0...HEAD
[14.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v13.0.0...v14.0.0
[13.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v12.0.0...v13.0.0
[12.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v11.2.0...v12.0.0
[11.2.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v11.1.0...v11.2.0
[11.1.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v11.0.0...v11.1.0
[11.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v10.0.1...v11.0.0
[10.0.1]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v10.0.0...v10.0.1
[10.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v9.0.3...v10.0.0
[9.0.3]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v9.0.2...v9.0.3
[9.0.2]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v9.0.0...v9.0.2
[9.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v8.0.0...v9.0.0
[8.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v7.0.0...v8.0.0
[7.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v6.0.0...v7.0.0
[6.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v5.1.0...v6.0.0
[5.1.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v5.0.0...v5.1.0
[5.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.9.0...v5.0.0
[4.9.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.8.0...v4.9.0
[4.8.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.7.0...v4.8.0
[4.7.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.6.1...v4.7.0
[4.6.1]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.6.0...v4.6.1
[4.6.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.5.1...v4.6.0
[4.5.1]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.5.0...v4.5.1
[4.5.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.4.2...v4.5.0
[4.4.2]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.4.1...v4.4.2
[4.4.1]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.4.0...v4.4.1
[4.4.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.3.0...v4.4.0
[4.3.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.2.0...v4.3.0
[4.2.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.1.0...v4.2.0
[4.1.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v4.0.0...v4.1.0
[4.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v3.5.0...v4.0.0
[3.5.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v3.4.0...v3.5.0
[3.4.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v3.3.0...v3.4.0
[3.3.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v3.1.1...v3.2.0
[3.1.1]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.8.0...v3.0.0
[2.8.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.7.1...v2.8.0
[2.7.1]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.7.0...v2.7.1
[2.7.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.6.0...v2.7.0
[2.6.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.4.2...v2.5.0
[2.4.2]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.4.1...v2.4.2
[2.4.1]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.4.0...v2.4.1
[2.4.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.9.0...v2.0.0
[1.9.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.8.1...v1.9.0
[1.8.1]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.8.0...v1.8.1
[1.8.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.2...v1.3.0
[1.2.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.1...v1.2
[1.1.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v1.0...v1.1
[1.0.0]: https://github.com/terraform-google-modules/cloud-foundation-fabric/compare/v0.1...v1.0
[#82]: https://github.com/terraform-google-modules/cloud-foundation-fabric/pull/82
[#103]: https://github.com/terraform-google-modules/cloud-foundation-fabric/pull/103
[#156]: https://github.com/terraform-google-modules/cloud-foundation-fabric/pull/156
<!-- markdown-link-check-enable -->
