# GCP Data Services examples

The examples in this folder implement **typical data service topologies** and **end-to-end scenarios**, that allow testing specific features like Cloud KMS to encrypt your data, or VPC-SC to mitigate data exfiltration.

They are meant to be used as minimal but complete starting points to create actual infrastructure, and as playgrounds to experiment with specific Google Cloud features.

## Examples

### GCE and GCS CMEK via centralized Cloud KMS

<a href="./cmek-via-centralized-kms/" title="CMEK on Cloud Storage and Compute Engine via centralized Cloud KMS"><img src="./cmek-via-centralized-kms/diagram.png" align="left" width="280px"></a> This [example](./cmek-via-centralized-kms/) implements [CMEK](https://cloud.google.com/kms/docs/cmek) for GCS and GCE, via keys hosted in KMS running in a centralized project. The example shows the basic resources and permissions for the typical use case of application projects implementing encryption at rest via a centrally managed KMS service.
<br clear="left">

### Cloud Storage to Bigquery with Cloud Dataflow
<a href="./gcs-to-bq-with-dataflow/" title="Cloud Storage to Bigquery with Cloud Dataflow"><img src="./gcs-to-bq-with-dataflow/diagram.png" align="left" width="280px"></a> This [example](./gcs-to-bq-with-dataflow/) implements [Cloud Storage](https://cloud.google.com/kms/docs/cmek) to Bigquery data import using Cloud Dataflow.
All resources use CMEK hosted in Cloud KMS running in a centralized project. The example shows the basic resources and permissions for the typical use case to read, transform and import data from Cloud Storage to Bigquery.
<br clear="left">

### Data Platform Foundations

<a href="./data-platform-foundations/" title="Data Platform Foundations"><img src="./data-platform-foundations/02-resources/diagram.png" align="left" width="280px"></a>
This [example](./data-platform-foundations/) implements a robust and flexible Data Foundation on GCP that provides opinionated defaults, allowing customers to build and scale out additional data pipelines quickly and reliably.
<br clear="left">

