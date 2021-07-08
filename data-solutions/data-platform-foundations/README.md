# Data Foundation Platform

The goal of this example is to Build a robust and flexible Data Foundation on GCP, providing opinionated defaults while still allowing customers to quickly and reliably build and scale out additional data pipelines.

The example is composed of three separate provisioning workflows, which are deisgned to be plugged together and create end to end Data Foundations, that support multiple data pipelines on top.

1. **[Environment Setup](./01-environment/)**
  *(once per environment)*
    * projects
    * VPC configuration
    * Composer environment and identity
    * shared buckets and datasets
1. **[Data Source Setup](./02-resources)**
  *(once per data source)*
    * landing and archive bucket
    * internal and external identities
    * domain specific datasets
1. **[Pipeline Setup](./03-pipeline)**
  *(once per pipeline)*
    * pipeline-specific tables and views
    * pipeline code
    * Composer DAG

The resulting GCP architecture is outlined in this diagram
![Target architecture](./02-resources/diagram.png)

A demo pipeline is also part of this example: it can be built and run on top of the foundational infrastructure to quickly verify or test the setup.

## Prerequisites

In order to bring up this example, you will need

- a folder or organization where new projects will be created
- a billing account that will be associated to new projects
- an identity (user or service account) with owner permissions on the folder or org, and billing user permissions on the billing account

## Bringing up the platform

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fterraform-google-modules%2Fcloud-foundation-fabric.git&cloudshell_open_in_editor=README.md&cloudshell_workspace=data-solutions%2Fdata-platform-foundations)

The end-to-end example is composed of 2 foundational, and 1 optional steps:

1. [Environment setup](./01-environment/)
1. [Data source setup](./02-resources/)
1. (Optional) [Pipeline setup](./03-pipeline/)

The environment setup is designed to manage a single environment. Various strategies like workspaces, branching, or even separate clones can be used to support multiple environments.

## TODO

| Description | Priority (1:High - 5:Low ) | Status | Remarks |
|-------------|----------|:------:|---------|
| DLP best practices in the pipeline | 2 | Not Started |   |
| Add Composer with a static DAG running the example | 3 | Not Started |   |
| Integrate [CI/CD composer data processing workflow framework](https://github.com/jaketf/ci-cd-for-data-processing-workflow) | 3 | Not Started |   |
| Schema changes, how to handle | 4 | Not Started |   |
| Data lineage | 4 | Not Started |   |
| Data quality checks | 4 | Not Started |   |
| Shared-VPC | 5 | Not Started |   |
| Logging & monitoring | TBD | Not Started |   |
| Orcestration for ingestion pipeline (just in the readme) | TBD | Not Started |   |
