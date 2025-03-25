# Data Platform

## Actors

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
