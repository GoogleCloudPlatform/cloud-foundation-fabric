# Data Platform

## Overview

This stage allows creation and management of a Data Platform. The solution is structured designed to enable the implementation of a reliable, robust, and scalable platform that supports the onboarding of new Data Products (or data workload) over time.

It establishes the platform's foundation but does not define the specifics of data handling, computation, or processing for individual workloads or data products, allowing them flexibility in technology choice. However, to optimize, standardize, and accelerate adoption, the platform encourages the use of shared patterns across data products, aiming to reduce implementation costs.

This solution implements [Data Mesh principles on Google Cloud Platform](https://cloud.google.com/architecture/data-mesh) and relies on established FAST stages for resource hierarchy, networking, and security. These aspects are considered pre-configured and are outside the scope of this document.

## Project Structure

The solution rappresent the following structure:

TODO: Add diagram

### Central Shared Services

Central teams enable the operation of the data mesh by providing cross-domain oversight, services, and governance. They reduce the operational burden for data domains in producing and consuming data products, and facilitate the cross-domain relationships that are required for the data mesh to operate.

This foundational project is centrally managed and it provides core, and platform-wide capabilities such as Security Tag, [Dataplex Catalog aspects)[https://cloud.google.com/dataplex/docs/enrich-entries-metadata] definition, [Policy tags](https://cloud.google.com/bigquery/docs/best-practices-policy-tags).

### Data Domain

A data domain is aligned with a business unit (BU), or a function within an enterprise. Common examples of business domains might be the mortgage department in a bank, or the customer, distribution, finance, or HR departments of an enterprise.

Each logical Data Domain will have its own isolated GCP Folder and project. This provides a clear organizational boundary and resource separation, and can be mapped to actual lines of business.

The Data domain project is the primary container for all services and resources specific to that domain. A shared  Cloud Composer environment is provisioned for orchestrating data workflows relevant to that domain. Composer will run with a dedicated IAM Service Account able to impersonate Data Product service account to guarantee the principle of least privilege.

### Data Product

Within each Data Domain, each Data Product reside in its own dedicated GCP Project. This enforces modularity, scalability, flexibility and clear ownership.

Withing the project created in this stage, the exposure layer of BigQuery and Cloud Storage will be deployed assigning the conresponding secure tag created in the central project to let IAM bindings created relying on IAM conditions.

A service account will be created with the ability of handling and preparing data to be stored in the exposure layer.

## Team and personas

For a data mesh to operate well, you must define clear roles for the people who perform tasks within the data mesh. Ownership is assigned to team archetypes, or functions. These functions hold the core user journeys for people who work in the data mesh. To clearly describe user journeys, they have been assigned to user roles. These user roles can be split and combined based on the circumstances of each enterprise.

The three main functions in a data mesh are as follows:

- *Central data team*: Defines and enforces structure of the data platform and data governance policies among data producers, ensuring high data quality and data trustworthiness for consumers. This team is often referred to as the data governance team.
TODO: Add roles on project/folder

- *Data domain teams*: These teams, aligned with specific business domains, are responsible for creating and maintaining data products over their lifecycle. This includes defining the data product's purpose, scope, and boundaries, developing and maintaining a product roadmap, implementing data security measures, ensuring compliance, and monitoring usage and performance.
TODO: Add roles on project/folder

- *Data Product teams*: There teams, alligned with specific data product are responsible of the developing, operate and maintaing the data product.
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
