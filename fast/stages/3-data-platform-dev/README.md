# Data Platform <!-- omit in toc -->

This Cloud Foundations Fabric FAST stage focuses on the creation and management of an opinonated Data Platform architecture based on Google Cloud best practices. Its architecture is designed to be reliable, robust, and scalable, facilitating the continuous onboarding of new Data Products (or data workloads).

<!-- BEGIN TOC -->
- [Design Overview \& Choices](#design-overview--choices)
  - [Resource Hierarchy Overview](#resource-hierarchy-overview)
  - [Data Platform Architecture](#data-platform-architecture)
    - [Central Services Project for Federated Governance](#central-services-project-for-federated-governance)
    - [Data Domain Folder(s) for Domain-Driven Ownership](#data-domain-folders-for-domain-driven-ownership)
    - [Data Product(s) for Data as a Product](#data-products-for-data-as-a-product)
  - [Teams and Personas](#teams-and-personas)
    - [Teams Archetypes](#teams-archetypes)
      - [Central Data Platform Team](#central-data-platform-team)
      - [Data Domain Teams](#data-domain-teams)
      - [Data Product Teams](#data-product-teams)
    - [Data product owner \[dp-product-a-0@\] \[dp-product-a-0-001@\]](#data-product-owner-dp-product-a-0-dp-product-a-0-001)
    - [Data Domain owner \[dp-domain-a@\] \[dp-domain-a-001@\]](#data-domain-owner-dp-domain-a-dp-domain-a-001)
    - [Data Platform owner (Central team) \[dp-platform-0@\] \[dp-platform-0-001@\]](#data-platform-owner-central-team-dp-platform-0-dp-platform-0-001)
    - [Data Consumer](#data-consumer)
  - [TODO](#todo)
  - [CUJ](#cuj)
  - [Fake data](#fake-data)
<!-- END TOC -->

# Design Overview & Choices

The Data Platform's foundation, established in this stage, provides core capabilities without prescribing specific data handling, computation, or processing for individual workloads or Data Products. This allows flexibility in the technology choices for individual data domains and teams. The platform's approach is to encourage shared patterns, aiming to optimize, standardize, accelerate adoption, and ultimately reduce implementation costs and management overhead across Data Products.

This Data Platform implementation closely aligned with [Data Mesh principles on Google Cloud Platform](https://cloud.google.com/architecture/data-mesh) and builds up on established [FAST stages](./fast/stages/README.md) for crucial aspects of Google Cloud Platform implementation like resource hierarchy, networking, and security. These FAST components are considered prerequisites and fall outside the direct scope of this stage.

## Resource Hierarchy Overview

The following diagram shows where the Data Platform and its associated resources sit in the organisation's resource hierarchy:

TODO: Add diagram

## Data Platform Architecture

The following diagram illustrates the high-level design of Data Platform projects and resources managed by this stage:

TODO: Add diagram

### Central Services Project for Federated Governance

Standardised central capabilities are provided to foster federated governance processes. These are implemented via established foundations that enable cross-domain data discovery, data sharing, self-service functionalities, and consistent governance. A key objective of these centrally managed services is to reduce the operational burden for data domains in producing and consuming data products, while also fostering the cross-domain collaboration necessary for the data mesh to operate efficiently.

Managed within a dedicated "Central Services" project, these central services deliver core, platform-wide capabilities. This includes, for example, configuring ["Secure" Tags](https://cloud.google.com/resource-manager/docs/tags/tags-overview), defining templates for [Dataplex Catalog Aspect Types)[https://cloud.google.com/dataplex/docs/enrich-entries-metadata], and enforcing data access through [Policy tags](https://cloud.google.com/bigquery/docs/best-practices-policy-tags).


### Data Domain Folder(s) for Domain-Driven Ownership

Another foundational principle of a data mesh architecture is domain-driven ownership. A Data Domain, in this context, typically aligns with a business unit (BU) or a distinct function within an enterprise. For instance, Data Domains could represent a bank's mortgage department, or an enterprise's customer, distribution, finance, or HR departments.

To support this ownership model and ensure clear separation, each logical Data Domain is provisioned with its own isolated GCP folder under the Data Platform parent with its collection of dedicated Google Cloud project(s). This structure establishes a distinct organizational boundary and resource separation, directly mapping to specific lines of business.

Within each Data Domain, a corresponding Google Cloud "Data Domain" project serves as the primary container for all its specific services and resources. A dedicated Cloud Composer environment is provisioned within this project for orchestrating the domain's data workflows. To adhere to the principle of least privilege, this Composer environment operates with a dedicated IAM Service Account capable of impersonating the necessary Data Product-specific service accounts within that domain.

### Data Product(s) for Data as a Product

Each Data Product within a Data Domain (which is organized under a GCP Folder) encapsulated in its own dedicated Google Cloud Project. This seperation is key to achieving modularity, scalability, flexibility, and distinct ownership for each product.

For every Data Product project created, its exposure layer (e.g. specific BigQuery datasets or Cloud Storage buckets) is carefully configured and deployed. This involves assigning the relevant "Secure Tags" that were established in the central services project. Applying these tags is crucial as it allows for the implementation of precise IAM bindings based on IAM conditions, thereby ensuring fine-grained and secure data access in line with least privilige principles.

## Teams and Personas

Effective data mesh operation relies on well-defined roles and responsibilities. Ownership is typically assigned to team archetypes, also referred to as functions. These functions represnts the core user journeys of individuals interacting with the data mesh. To clearly describe these journeys, specific user roles are defined within these functions. These user roles can be split or combined bases on specific needs and the scale of each enterprise.

### Teams Archetypes

The three primary functions (or team archetypes) in this data mesh are:

#### Central Data Platform Team

This function defines the overall data platform architecture, establishes shared infrastructure, and enforces central data governance policies and standards across the data mesh. It enables data producers with tools, paved path solutions and best practices, ensuring high data quality, security, and trustworthiness for consumers. Its focus is on providing the foundations of a self-serve data platform as well as universal governance standards for all users.

TODO: Add roles on project/folder

#### Data Domain Teams

Aligned with specific business areas (e.g., customer, finance, distribution), this function holds clearly defined ownership of data within that domain. Key responsibilities include establishing and upholding a data product's purpose, scope, and boundaries. This is achieved through ongoing activities such as:
- Creating and maintaining its domain-wide data product roadmap.
- Implementing robust data security measures.
- Ensuring adherence to all relevant compliance obligations.
- Continuously monitoring usage and performance.

TODO: Add roles on project/folder

#### Data Product Teams

This function is responsible for the end-to-end lifecycle of a specific data product. Data Product Teams (which may be part of or work closely with a Data Domain Team) develop, operate, and maintain their assigned data product. Their tasks include defining the data product's schema and interfaces, implementing data ingestion and transformation pipelines, ensuring data quality and security for their product, managing its roadmap, and supporting its consumers.

TODO: Add roles on project/folder

### Data product owner [dp-product-a-0@] [dp-product-a-0-001@]

- Editor on Data Product
- Composer roles on DataDomain

### Data Domain owner [dp-domain-a@] [dp-domain-a-001@]

- Editor on DataDomain
- Viewer on DataProducts (NO)

### Data Platform owner (Central team) [dp-platform-0@] [dp-platform-0-001@]

- Editor on Central
- Viewer on DataDomain/Product (NO)

### Data Consumer

- DataCatalog on DataPlatform (with condition)
- Ad-hoc Data product BigQuery viewer (with condition)

## TODO

Add support for:

- CMEK
- VPC
- Composer

Modules:

- [BigQuery Data Policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_datapolicy_data_policy)
- Add Factory support to [Policy TAG](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/data-catalog-policy-tag)
- [BigQuery Reservation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_bi_reservation)
- [Aspects Type](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataplex_aspect_type)
- [Analycts Hub](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_analytics_hub_data_exchange)

Actors:

- Add Data Domain team

Conditions for roles:

- GCS Name = resource.name.startsWith('projects/_/buckets/example-bucket')
- projects/project-id/datasets/dataset-id

## CUJ

- As Data Platform Owner:
  - Create Taxonomy (via Tag Template)
  - Create Policy TAG (Via Data Cat.)
  - Create Dynamic Data Masked on a Policy TAG

- As Data Product Owner:
  - Create Dataset (L0, L1), Table, View, Auth View
  - Insert Data into L0, L1
  - Tag Template view on central project
  - TAG template, bind tag template on Table, column
  - Create row level policy
  - Create a Data Policy on Policy TAG (Manually, at the moment not supported by TF Fabric module)
  
- As Consumer:
  - See exposure metadata from BQ console
  - See exposure metadata from Dataplex ([limitation](https://cloud.google.com/bigquery/docs/tags#limitations) due to condition)
  - Query Exposure Auth view
  - Query Filtered Data (Row Level Policy)
  - Query Dynamic Data Masked data on a table

## Fake data

```sql

CREATE SCHEMA `yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0` OPTIONS (location="europe-west8");
CREATE SCHEMA `yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l1` OPTIONS (location="europe-west8");

CREATE OR REPLACE TABLE yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.customers (
    id NUMERIC,
    name STRING,
    surname STRING
);

DELETE FROM yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.customers WHERE TRUE;
INSERT INTO yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.customers VALUES (1,'Giovanni','Rossi');
INSERT INTO yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.customers VALUES (2,'Alberto','Bianchi');

CREATE OR REPLACE TABLE yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.orders (
    id NUMERIC,
    customer_id NUMERIC,
    item STRING,
    quantity NUMERIC,
    price NUMERIC
);

DELETE FROM yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.orders WHERE TRUE;
INSERT INTO yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.orders VALUES (1,1,'Umbrella',1,10);
INSERT INTO yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.orders VALUES (2,1,'Car',1,1000);
INSERT INTO yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.orders VALUES (3,2,'Car',1,1200);

CREATE OR REPLACE TABLE yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l1.customer_orders AS
SELECT
    c.id AS customer_id,
    c.name,
    c.surname,
    o.id AS order_id,
    o.item,
    o.quantity,
    o.price
FROM
    yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.customers AS c
JOIN
    yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l0.orders AS o ON c.id = o.customer_id;

CREATE OR REPLACE VIEW yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_exposure_0.customer_order_view AS
SELECT
    customer_id,
    name,
    surname,
    order_id,
    item,
    quantity,
    price
FROM
    yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l1.customer_orders;

CREATE OR REPLACE ROW ACCESS POLICY
  item_filter
ON
  `yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l1.customer_orders` GRANT TO ("group: data-consumer-bi-01@yoyoland.joonix.net")
FILTER USING
  (item="Car" );

DROP ALL ROW ACCESS POLICIES ON `yy-dev-dp-t0-p0-0.yy_dev_dp_t0_p0_l1.customer_orders`;  
```
