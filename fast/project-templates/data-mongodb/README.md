# MongoDB Atlas

This simple setup allows creating and configuring a managed [MongoDB Atlas](https://cloud.google.com/mongodb) cluster, and connecting it to a local VPC network via Private Endpoints.

## Prerequisites

The [`project.yaml`](./project.yaml) file describes the project-level configuration needed in terms of API activation and IAM bindings.

If you are deploying this inside a FAST-enabled organization, the file can be lightly edited to match your configuration, and then used directly in the [project factory](../../stages/2-project-factory/).

This Terraform can of course be deployed using any pre-existing project. In that case use the YAML file to determine the configuration you need to set on the project:

- enable the APIs listed under `services`
- grant the permissions listed under `iam` to the principal running Terraform, either machine (service account) or human

## Variable Configuration

Configuration is mostly done via the `atlas_config` and `vpc_config` variables. Note that:

- VPC configuration can be set to reference a Shared VPC Host network like shown below, or an in-project network if that is preferred
- the PSC CIDR block is used to allocate the required 50 endpoint addresses in the VPC, so it needs to be large enough to accommodate them
- the Atlas region must match the GCP subnetwork region

Bringing up a cluster and the associated connectivity from scratch will require approximately 30 minutes.

```hcl
atlas_config = {
  cluster_name     = "test-0"
  organization_id  = "fmoajt0b2fwdvp9yvu7m7zl2"
  project_name     = "my-atlas-project"
  region           = "NORTH_AMERICA_NORTHEAST_1"
  database_version = "7.0"
  instance_size    = "M10"
  provider = {
    public_key  = "xxxx"
    private_key = "xxxxx-xxxx-xxxx-xxxx-xxxxxxxx"
  }
}
project_id = "my-prod-shared-mongodb-0"
vpc_config = {
  network_name   = "dev-spoke-0"
  subnetwork_id  = "projects/my-dev-net-spoke-0/regions/northamerica-northeast1/subnetworks/gce"
  psc_cidr_block = "10.8.11.192/26"
}
# tftest skip
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [atlas_config](variables.tf#L17) | MongoDB Atlas configuration. | <code title="object&#40;&#123;&#10;  cluster_name     &#61; string&#10;  organization_id  &#61; string&#10;  project_name     &#61; string&#10;  region           &#61; string&#10;  database_version &#61; optional&#40;string&#41;&#10;  instance_size    &#61; optional&#40;string&#41;&#10;  provider &#61; object&#40;&#123;&#10;    private_key &#61; string&#10;    public_key  &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L40) | Project id where the registries will be created. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L45) | VPC configuration. | <code title="object&#40;&#123;&#10;  psc_cidr_block &#61; string&#10;  network_name   &#61; string&#10;  subnetwork_id  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L33) | Prefix used for all resource names. | <code>string</code> |  | <code>&#34;mongodb&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [atlas_cluster](outputs.tf#L17) | MongoDB Atlas cluster. |  |
| [atlas_project](outputs.tf#L31) | MongoDB Atlas project. |  |
| [endpoints](outputs.tf#L40) | MongoDB Atlas endpoints. |  |
<!-- END TFDOC -->
## Test

```hcl
module "test" {
  source = "./fabric/fast/project-templates/data-mongodb"
  atlas_config = {
    cluster_name     = "test-0"
    organization_id  = "fmoajt0b2fwdvp9yvu7m7zl2"
    project_name     = "my-atlas-project"
    region           = "NORTH_AMERICA_NORTHEAST_1"
    database_version = "7.0"
    instance_size    = "M10"
    provider = {
      public_key  = "xxxx"
      private_key = "xxxxx-xxxx-xxxx-xxxx-xxxxxxxx"
    }
  }
  project_id = "my-prod-shared-mongodb-0"
  vpc_config = {
    network_name   = "dev-spoke-0"
    subnetwork_id  = "projects/my-dev-net-spoke-0/regions/northamerica-northeast1/subnetworks/gce"
    psc_cidr_block = "10.8.11.192/26"
  }
}
# tftest modules=2 resources=104
```
