# Data Platform Dataset

This dataset configures an opinionated Data Platform architecture based on Google Cloud best practices, managed via the Project Factory.

Its architecture is designed to be reliable, robust, and scalable, facilitating the continuous onboarding of new Data Products (or data workloads).

## Design Overview and Choices

### Data Platform Architecture

The following diagram represent the high-level architecture of the Data Platform related projects and their associated resources managed by this dataset:

<p align="center">
  <img src="diagram-data-platform.png" alt="High level diagram.">
</p>

### Folder and Project Structure

The dataset manages the following three high-level logical components implemented via GCP folders and projects:

- "Central Shared Services", a single central project, in which Dataplex Catalog Aspect Types, Policy Tags, and Resource Manager tags a.k.a. "Secure Tags" are defined
- one or more "Data Domains", each composed of a folder with a top-level shared project hosting shared resources such as Composer at the domain level, and an additional sub-folder for hosting data products e.g. "Data Products"
- one or more "Data Products" per domain, each composed of a project, and related resources that are optional

<p align="center">
<img src="diagram-folders.png" alt="Folder structure." width=500px />
</p>

#### Central Shared Services (Federated Governance)

Central Shared Services Project provides the standardized central capabilities to foster federated governance processes. These are implemented via established foundations that enable cross-domain data discovery, data sharing, self-service functionalities, and consistent governance.

Core, platform-wide capabilities are delivered as shared services managed within a dedicated "Central Shared Services" project. These capabilities include:

- [Dataplex Catalog Aspect Types](https://cloud.google.com/dataplex/docs/enrich-entries-metadata): Defined in `aspect-types/`.
- [Policy Tags](https://cloud.google.com/bigquery/docs/best-practices-policy-tags): Configured via the `central_project_config.policy_tags` variable (if applicable) or YAML.

#### Data Domains (Domain-Driven Ownership)

A Data Domain typically aligns with a business unit (BU) or a distinct function within an enterprise. To support this ownership model, each logical Data Domain is provisioned with its own isolated GCP folder.

Within each Data Domain, a corresponding Google Cloud "Data Domain" project serves as the primary container for all its specific services and resources. A dedicated Cloud Composer environment is provisioned within this project for orchestrating the domain's data workflows.

#### Data Products (DaaP)

Each Data Product within a Data Domain is encapsulated in its own dedicated Google Cloud Project. This separation is key to achieving modularity, scalability, flexibility, and distinct ownership for each product.

### Teams and Personas

Effective data mesh operation relies on well-defined roles and responsibilities.

| Group | Central Shared Services Project | Data Domain Folder | Data Product Project |
| - | :-: | :-: | :-: |
| Central Data Platform Team | `ADMIN` | `Log and Metrics Viewer` | `Log and Metrics Viewer` |
| Data Domain Team | `READ/USAGE` | `ADMIN` | `Log and Metrics Viewer` |
| Data Product Team | `READ/USAGE` | `READ/USAGE` | `ADMIN` |

#### Central Data Platform Team

This team defines the overall data platform architecture, establishes shared infrastructure, and enforces central data governance policies and standards across the data mesh.

#### Data Domain Team

Aligned with specific business areas (e.g., customer, finance, distribution), this team holds clearly defined ownership of data within that domain. They are responsible for the domain-wide data product roadmap and security.

#### Data Product Team

This team is responsible for the end-to-end lifecycle of a specific Data Product. They develop, operate, and maintain their assigned Data Product, including ingestion, transformation, and exposure.

## Usage with Project Factory

To deploy this dataset using `2-project-factory`:

1.  Set `factories_config.dataset` to `"datasets/data-platform"`.
2.  Ensure `factories_config.paths.vpcs` is configured (or relies on module defaults).

```bash
terraform apply -var 'factories_config={dataset="datasets/data-platform"}'
```

The YAML configuration files for this dataset are located in this directory (`datasets/data-platform`).

## Deployment Choices

The Data Platform dataset allows for flexibility in networking models, supporting both Shared VPCs (standard enterprise pattern) and Project-Local VPCs (isolated workloads).

### Shared VPCs (Default)

The default and recommended networking model for the Data Platform uses Shared VPCs managed in the `2-networking` stage.
In this mode, Data Domain and Data Product projects are attached as service projects to the Shared VPC host projects defined in `host_project_ids` variable.

This approach centralizes network management, simplifies connectivity between domains, and aligns with the typical FAST landing zone architecture.
Projects automatically inherit network connectivity based on the `shared_vpc_service_config` in their YAML definitions or defaults.

### Project-Local VPCs

This folder can contain YAML files defining VPCs that are local to specific projects.
The structure should follow the `net-vpc-factory` pattern:

1.  Create a folder for the VPC (e.g., `my-vpc-0`).
2.  Inside that folder, create a `.config.yaml` file.
3.  Define the VPC configuration in `.config.yaml` (see `net-vpc-factory` module documentation for schema details).

Example `.config.yaml` (e.g. `domain-0/.config.yaml`):

```yaml
name: domain-0
project_id: $project_ids:shared-0 # Use context interpolation for project IDs
subnets:
  - name: default
    ip_cidr_range: 10.0.0.0/24
    region: $locations:primary
```

Note: You must also enable the `vpcs` factory path in your `terraform.tfvars` or `*.auto.tfvars` file if it's not enabled by default:

```hcl
factories_config = {
  paths = {
    vpcs = "vpcs"
  }
}
```
