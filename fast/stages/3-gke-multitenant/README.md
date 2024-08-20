# GKE Multitenant stage

This directory contains a stage that can be used to centralize management of GKE multinenant clusters.

The Terraform code follows the same general approach used for the [project factory](../2-project-factory/) and [data platform](../3-data-platform/) stages, where a "fat module" contains the stage code and is used by thin code wrappers that localize it for each environment or specialized configuration:

The [`dev` folder](./dev/) contains an example setup for a generic development environment, and can be used as-is or cloned to implement other environments, or more specialized setups

Refer to [the `dev` documentation](./dev/README.md) configuration details, and to [the `gke-serverless` documentation](../../../blueprints/gke/multitenant-fleet) for the architectural design and decisions taken.
