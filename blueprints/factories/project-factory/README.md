# Project Factory

This is a working example of how to manage project creation at scale, by wrapping the [project module](../../../modules/project/) and driving it via external data, either directly provided or parsed via YAML files.

The wrapping layer around the project module is intentionally thin, so that

- all the features of the project module are available
- no "magic" or hidden side effects are implemented in code
- debugging and integration of new features is simple

The code is meant to be executed by a high level service accounts with powerful permissions:

- Shared VPC connection if service project attachment is desired
- project creation on the nodes (folder or org) where projects will be defined

The module also supports optional creation of specific resources that usually part of the project creation flow:

- service accounts used for VM instances, and associated basic roles
- KMS key encrypt/decrypt permissions for service identities in the project
- membership in VPC SC standard or bridge perimeters

Compared to the previous version of this code, network-related resources (DNS zones, VPC subnets, etc.) have been removed as they are not typically in scope for the team who manages project creation, and adding them when needed requires just a few trivial code changes.

## Example

```hcl
module "project-factory" {
  source = "./fabric/blueprints/factories/project-factory"
  data_defaults = {
    billing_account = "012345-67890A-ABCDEF"
  }
  data_merges = {
    labels = {
      environment = "test"
    }
    services = [
      "stackdriver.googleapis.com"
    ]
  }
  data_overrides = {
    contacts = {
      "admin@example.com" = ["ALL"]
    }
    prefix = "test-pf"
  }
  factory_data = {
    data_path = "data"
  }
}
# tftest modules=6 resources=12 files=prj-app-1,prj-app-2 inventory=example.yaml
```

```yaml
billing_account: 012345-67890A-BCDEF0
labels:
 app: app-1
 team: foo
parent: folders/12345678
service_encryption_key_ids:
 compute:
 - projects/kms-central-prj/locations/europe-west3/keyRings/my-keyring/cryptoKeys/europe3-gce
services:
- storage.googleapis.com
service_accounts:
  app-1-be: {}
  app-1-fe: {}

# tftest-file id=prj-app-1 path=data/prj-app-1.yaml
```

```yaml
labels:
 app: app-1
 team: foo
parent: folders/12345678
service_accounts:
  app-2-be: {}

# tftest-file id=prj-app-2 path=data/prj-app-2.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [factory_data](variables.tf#L85) | Project data from either YAML files or externally parsed data. | <code title="object&#40;&#123;&#10;  data      &#61; optional&#40;map&#40;any&#41;&#41;&#10;  data_path &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [data_defaults](variables.tf#L17) | Optional default values used when corresponding project data from files are missing. | <code title="object&#40;&#123;&#10;  billing_account            &#61; optional&#40;string&#41;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  parent                     &#61; optional&#40;string&#41;&#10;  prefix                     &#61; optional&#40;string&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  service_perimeter_bridges  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  service_perimeter_standard &#61; optional&#40;string&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  shared_vpc_service_config &#61; optional&#40;object&#40;&#123;&#10;    host_project         &#61; string&#10;    service_identity_iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_iam_grants   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;, &#123; host_project &#61; null &#125;&#41;&#10;  tag_bindings &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    default_roles &#61; optional&#40;bool, true&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_merges](variables.tf#L45) | Optional values that will be merged with corresponding data from files. Combines with `data_defaults`, file data, and `data_overrides`. | <code title="object&#40;&#123;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  service_perimeter_bridges  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    default_roles &#61; optional&#40;bool, true&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_overrides](variables.tf#L64) | Optional values that override corresponding data from files. Takes precedence over file data and `data_defaults`. | <code title="object&#40;&#123;&#10;  billing_account            &#61; optional&#40;string&#41;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  parent                     &#61; optional&#40;string&#41;&#10;  prefix                     &#61; optional&#40;string&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  service_perimeter_bridges  &#61; optional&#40;list&#40;string&#41;&#41;&#10;  service_perimeter_standard &#61; optional&#40;string&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    default_roles &#61; optional&#40;bool, true&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [projects](outputs.tf#L17) | Project module outputs. |  |
| [service_accounts](outputs.tf#L22) | Service account emails. |  |
<!-- END TFDOC -->
