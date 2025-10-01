# FAST release upgrading notes

This file only mentions changes that require changes to Terraform variables, or replace existing resources. "Soft" additions like new features or optional attributes are non-breaking and not considered here.

If the address of a resource has changed between FAST versions, we usually created a file in `fast/stages/n-STAGENAME/moved/` which contains a number of [moved blocks](https://developer.hashicorp.com/terraform/language/moved) which can be copied to the n-stagename directory before executing `terraform plan` or `terraform apply`.

We do an effort at covering most stages, but don't typically cover multitenant and stage 3s as there's too much variance in use cases and potential configurations.

As usual, consider this a guideline with no guarantees. Migrations between FAST releases are actively discouraged for production, and mostly make sense only when developing or testing new features.

<!-- markdownlint-disable MD024 -->

> v44.0.0 and v45.0.0 deprecated several legacy stages, refer to those releases or branches for legacy upgrading instructions. Upgrades from legacy to current stages are not directly supported.

<!-- BEGIN TOC -->
<!-- END TOC -->
