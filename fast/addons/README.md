# FAST add-ons

Each of the folders contained here is a separate "add-on" that can be used to add extra functionality to a specific stage.

Add-ons can be thought of as additional thin layers on top of a stage, that reuse its IaC resources and leverage the same IAM configuration: the same service accounts are used to run the add-on, and state configuration is stored in the same bucket as their "parent stage" under a different prefix.

The only dedicated resources that can be optionally defined for add-ons are to enable CI/CD functionality, so that a dedicated repository can be used to host the add-on code and pipeline.

Add-ons are currently only implemented for stage 1 (resource management and VPC-SC), and stage 2 (networking, project factory, security).

## Add-on configuration

To configure an add-on:

- its "parent stage" (the stage the add-on augments) needs to be enabled and applied, so that the IaC and IAM configurations the add-on uses are present
- the `fast_addon` variable in the stage controlling the "parent stage" (boostrap for a stage 1 add-on, resource management for a stage 2 add-on) is configured and the stage applied, so that the add-on provider and optional CI/CD resources are created
- the provider and relevant FAST output variable files are linked or copied in the add-on folder (e.g. via the `fast-links.sh` script)

At this point the add-on can be run, and operate on the same folders, projects and resources controlled by its "parent stage".

Add-ons typically generate their own FAST output variable files, which can be optionally consumed by downstream stages.

This is an example configuration of the `fast_addon` variable in the resource management stage, to enable running the NGFW networking add-on. The CI/CD configuration block is optional, and commented out here.

```hcl
fast_addon = {
  networking-ngfw = {
    parent_stage = "2-networking"
    # cicd_config = {
    #   identity_provider = "github-test"
    #   repository = {
    #     name   = "test/ngfw"
    #     type   = "github"
    #     branch = "main"
    #   }
    # }
  }
}
```

This configuration will create `tfvars/2-networking-ngfw-providers.tf` and
`tfvars/2-networking-ngfw-r-providers.tf` provider files in the GCS output bucket and local folder (if configured).
