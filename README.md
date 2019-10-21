# Cloud Foundation Toolkit - Fabric

Cloud Foundation Fabric provides end-to-end Terraform code examples on GCP, which are meant for prototyping and as minimal samples to aid in designing real-world infrastructures. As such, these samples are meant to be adapted and updated for your different use cases, and often do not implement GCP security best practices for production use.

All the examples leverage composition, combining different Cloud Foundation Toolkit modules to realize an integrated design. Additional modules can be combined in to tailor the examples to specific needs, and to implement additional best practices. You can check the [full list of Cloud Foundation Toolkit modules here](https://github.com/terraform-google-modules).

The examples are organized into two main sections: GCP foundational design, and infrastructure design

## Foundational examples

Foundational examples deal with organization-level management of GCP resources, and take care of folder hierarchy, initial automation requirements (service accounts, GCS buckets), and high level best practices like audit log exports and organization policies.

They are simplified versions of real-life use cases, and put a particular emphasis on separation of duties at the environment or tenant level, and decoupling high level permissions from the day to day running of infrastructure automation. More details and the actual examples are available in the [foundations folder](foundations).

## Infrastructure examples

Infrastructure examples showcase typical networking configurations on GCP, and are meant to illustrate how to automate them with Terraform, and to offer an easy way of testing different scenarios. Like the foundational examples, they are simplified versions of real-life use cases. More details and the actual examples are available in the [infrastructure folder](infrastructure).
