# Resource Factories

This README explains the rationale and high level approach for resource factories, a pattern that is widely used in this repository across modules and in the FAST framework. It also collects pointers to all the different factories implemented in modules to simplify discovery.

<!-- BEGIN TOC -->
- [The why](#the-why)
- [The how](#the-how)
- [Factory implementations](#factory-implementations)
  - [Module-level factory interfaces](#module-level-factory-interfaces)
  - [Standalone factories](#standalone-factories)
<!-- END TOC -->

## The why

Managing large sets of uniform resources with Terraform usually involves different teams collaborating on the same codebase, complex authorization processes and checks managed via CI/CD approvals, or even integrating with external systems that manage digital workflows.

Factories are a way to simplify all above use cases, by moving repetitive resource definitions out of the Terraform codebase and into sets of files that leverage different formats.

Using factories, repetitive resource creation and management becomes easier

- for humans who have no direct experience with Terraform, by exposing filesystem hierarchies and YAML-based configuration data
- for connected systems, by accepting well-known data exchange formats like JSON or CSV
- for external code that needs to enforce checks or policies, by eliminating the need to parse HCL code or Terraform outputs
- to implement authorization processes or workwflows in CI/CD, by removing the dependency on Terraform and HCL knowledge for the teams involved

## The how

Fabric resource-level factories can be broadly split into two different types

- simple factories that manage one simple resource type (firewalls, VPC-SC policies)
- complex factories that manage a set of connected resources to implement a complex flow that is usually perceived as a single unit (project creation)

The first factory type is implemented at the module level, where one module exposes one or more factories for some of the resources that depend on the main module resource (e.g. firewall rules for a VPC). The main goal with this approach is to simplify resource management at scale by removing the dependency on Terraform and HCL.

These factories are often designed as module-level interfaces which are then exposed by any module that manages a specific type of resource. All these factories leverage a single `factory_configs` variable, that allows passing in the paths for all the different factories supported in the module.

The second factory type is implemented as a standalone module that internally references other modules, and implements complex management of different resource sets as part of a single process implemented via the factory. The typical example is the project factory, that brings together the project, service accounts, and billing accounts modules to cover all the main aspects of project creation as a single unit.

## Factory implementations

### Module-level factory interfaces

- **BigQuery Analicts Hub rules**
  - [`analytics-hub`](../../modules/analytics-hub/README.md#factory)
- **billing budgets**
  - [`billing-account`](../../modules/billing-account/README.md#budget-factory)
- **Data Catalog tags**
  - [`data-catalog-tag`](../../modules/data-catalog-tag/README.md#factory)
- **Data Catalog tag templates**
  - [`data-catalog-tag-template`](../../modules/data-catalog-tag-template/README.md#factory)
- **Dataplex Datascan rules**
  - [`dataplex-datascan`](../../modules/dataplex-datascan/README.md)
- **firewall policy**
  - [`net-firewall-policy`](../../modules/net-firewall-policy/README.md#factory)
- **IAM custom roles**
  - [`organization`](../../modules/organization/README.md#custom-roles-factory)
  - [`project`](../../modules/project/README.md#custom-roles-factory)
- **organization policies**
  - [`organization`](../../modules/organization/README.md#organization-policy-factory)
  - [`folder`](../../modules/folder/README.md#organization-policy-factory)
  - [`project`](../../modules/project/README.md#organization-policy-factory)
- **organization policy custom constraints**
  - [`organization`](../../modules/organization/README.md#organization-policy-custom-constraints-factory)
- **DNS response policy rules**
  - [`dns-response-policy`](../../modules/dns-response-policy/README.md#define-policy-rules-via-a-factory-file)
- **VPC firewall rules**
  - [`net-vpc-firewall`](../../modules/net-vpc-firewall/README.md#rules-factory)
- **VPC subnets**
  - [`net-vpc`](../../modules/net-vpc/README.md#subnet-factory)
- **VPC-SC access levels and policies**
  - [`vpc-sc`](../../modules/vpc-sc/README.md#factories)

### Standalone factories

- **projects**
  - [`project-factory`](../../modules/project-factory/)
