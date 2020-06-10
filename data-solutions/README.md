# GCP Data Services examples

The examples in this folder implement **typical data service topologies** and **end-to-end scenarios**, that allow testing specific features like Cloud KMS to encrypt your data, or VPC-SC to mitigate data exfiltration.

They are meant to be used as minimal but complete starting points to create actual infrastructure, and as playgrounds to experiment with specific Google Cloud features.

## Examples

### CMEK for Cloud Storage and Compute Engine via centralized KMS

<a href="./cmek-via-centralized-kms/" title="CMEK on Cloud Storage and Compute Engine via centralized Cloud KMS"><img src="./cmek-via-centralized-kms/diagram.png" align="left" width="280px"></a> This [example](./cmek-via-centralized-kms/) implements [CMEK](https://cloud.google.com/kms/docs/cmek) for GCS and GCE, via keys hosted in KMS running in a centralized project. The example shows the basic resources and permissions for the typical use case of application projects implementing encryption at rest via a centrally managed KMS service.
