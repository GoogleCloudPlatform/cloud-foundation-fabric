# Deprecated: Terraform Blueprints for Google Cloud

**This directory is deprecated as of release `v44.0.0`.**

The blueprints that were previously in this directory have been deprecated. Some of the old blueprints will be refactored as either FAST project templates or module-level recipes.

If there is a specific blueprint that you would like to see refactored, please open a feature request.

## Accessing the Deprecated Blueprints

The last version of the blueprints is available in the `v43.0.0` tag. You can still use them by referencing this tag in your Terraform configuration.

For example, to use a blueprint from the `v43.0.0` release, you can use the following format in your module source, which uses the `ref` attribute to pin the version:

```terraform
module "gke" {
  source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//blueprints/gke/autopilot?ref=v35.0.0"
  project_create = {
    billing_account_id = "12345-12345-12345"
    parent             = "folders/123456789"
  }
  project_id = "my-project"
}
```

You can browse the complete list of blueprints and their documentation in the [`v43.0.0` blueprints directory](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/v43.0.0/blueprints).