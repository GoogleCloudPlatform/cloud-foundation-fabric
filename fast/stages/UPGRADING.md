# FAST release upgrading notes

Only changes impacting Terraform variables or actual resources are noted here.

<!-- BEGIN TOC -->
<!-- END TOC -->

## v35.1.0 to v36.0.0

### Bootstrap stage

**Breaking changes:**

- the `factories_config.org_policy` variable attribute has been renamed to `factories_config.org_policies`

**Non-breaking changes:**

- two new custom roles have been added: `gcveNetworkViewer` and `projectIAMViewer`
- organization policies for the IaC project have been moved to a factory, default policies are in `data/org-policies-iac`

### Resource Management stage

**Breaking changes:**

- the "Data Platform" stage 3 has been removed in preparation of a completely revised state, any associated resource (service accounts, folders, buckets, etc.) will be destroyed
- billing IAM roles will be destroyed and recreated as they are now driven by a loop and their names have changed

**Non-breaking changes:**

- GCS and local output files will be recreated
