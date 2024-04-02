# Google Cloud VMware Engine Stage

The GCVE stage builds on top of your foundations to create and set up projects and related resources, used for your Google Cloud VMware Engine (GCVE) private cloud environments.
It is organized in folders representing environments (e.g. `dev`, `prod`), each implemented by a stand-alone Terraform setup.

This directory contains a [GCVE single region private cloud for the `prod` environment](./prod/) that can be used as-is, and cloned with few changes to implement further environments. Refer to the example [`prod`/README.md](./prod/README.md) for configuration details.

With this stage and the [GCVE blueprints](./../../../blueprints/gcve/), you can rapidly deploy production-ready GCVE environments. These environments are fully optimized to integrate seamlessly with your Fabric FAST network topology. Explore the deployment patterns below to find the perfect fit for your use case."

## TOC

<!-- BEGIN TOC -->
- [TOC](#toc)
- [Deployment Patterns](#deployment-patterns)
  - [Single Region](#single-region)
    - [Standalone VPC for a sigle region GCVE deployment](#standalone-vpc-for-a-sigle-region-gcve-deployment)
    - [Separate VPC Environments for individual dedicated GCVE deployments](#separate-vpc-environments-for-individual-dedicated-gcve-deployments)
<!-- END TOC -->

## Deployment Patterns
### Single Region
#### Standalone VPC for a sigle region GCVE deployment
<p align="center">
  <img src="diagram0.png" alt="Standalone Shared VPC for a sigle region GCVE deployment">
</p>

#### Separate VPC Environments for individual dedicated GCVE deployments 
<p align="center">
  <img src="diagram1.png" alt="Separate VPC Environments for individual dedicated GCVE deployments">
</p>


<!-- BEGIN TFDOC -->
<!-- END TFDOC -->