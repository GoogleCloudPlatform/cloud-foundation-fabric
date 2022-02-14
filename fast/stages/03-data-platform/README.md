# Data Platform

The Data Platform builds on top of your foundations to create and set up projects and related resources, used for your data workloads and pipelines.
It is organized in folders representing environments (e.g. `dev`, `prod`), each implemented by a stand-alone Terraform setup.

This directory contains a [Data Platform for the `dev` environment](./dev/) that can be used as-is, and cloned with few changes to implement further environments. Refer to the example [`dev/README.md`](./dev/README.md) for configuration details.
