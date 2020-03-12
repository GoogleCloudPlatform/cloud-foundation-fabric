# Google Cloud Terraform Modules and Examples

This repository provides a **suite of Terraform modules** and **end-to-end examples** for Google Cloud, which are meant for prototyping and as initial samples to aid in designing real-world infrastructures.

The whole repository is meant to be **cloned as a single unit**, and then forked into separate owned repositories for real usage, or used as-is and periodically updated as a complete toolkit for prototyping.

## Modules

All the included modules have **similar interfaces** as they are designed for composition, and as a basis to support custom changes in the fork-and-own model.

All the examples leverage composition, combining different Cloud Foundation Toolkit modules to realize an integrated design. Additional modules can be combined in to tailor the examples to specific needs, and to implement additional best practices. You can check the [full list of Cloud Foundation Toolkit modules here](https://github.com/terraform-google-modules).

The examples are organized into two main sections: GCP foundational design, and infrastructure design

## Foundational examples

Foundational examples deal with organization-level management of GCP resources, and take care of folder hierarchy, initial automation requirements (service accounts, GCS buckets), and high level best practices like audit log exports and organization policies.

They are simplified versions of real-life use cases, and put a particular emphasis on separation of duties at the environment or tenant level, and decoupling high level permissions from the day to day running of infrastructure automation. More details and the actual examples are available in the [foundations folder](foundations).

## Infrastructure examples

Infrastructure examples showcase typical networking configurations on GCP, and are meant to illustrate how to automate them with Terraform, and to offer an easy way of testing different scenarios. Like the foundational examples, they are simplified versions of real-life use cases. More details and the actual examples are available in the [infrastructure folder](infrastructure).
