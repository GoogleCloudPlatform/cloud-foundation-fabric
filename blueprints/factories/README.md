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

Using factories, repetive resource creation and management becomes easier

- for humans who have no direct experience with Terraform, by exposing filesystem hierarchies and YAML-based configuration data
- for connected systems, by accepting well know data exchange formats like JSON or CSV
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
  - `analytics-hub`
- **billing budgets**
  - `billing-account`
- **Data Catalog tags**
  - `data-catalog-tag`
- **Data Catalog tag templates**
  - `data-catalog-tag-template`
- **Dataplex Datascan rules**
  - `dataplex-datascan`
- **firewall policy rules**
  - `net-firewall-policy`
- **hierarchical firewall policies**
  - `folder`
  - `project`
- **IAM custom roles**
  - `organization`
  - `project`
- **organization policies**
  - `organization`
  - `folder`
  - `project`
- **organization policy custom constraints**
  - `organization`
- **DNS response policy rules**
  - `dns-response-policy`
- **VPC firewall rules**
  - `net-vpc-firewall`
- **VPC subnets**
  - `net-vpc`
- **VPC-SC access levels and policies**
  - `vpc-sc`

### Standalone factories

- **projects**
  - `project-factory`
