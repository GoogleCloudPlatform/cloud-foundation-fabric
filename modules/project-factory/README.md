# Project Factory

This module implements in code the end-to-end project creation process for multiple projects via YAML data configurations.

It supports

- all project-level attributes exposed by the [project module](../project/), including Shared VPC host/service configuration
- optional service account creation in the project, including basic IAM grants
- KMS key encrypt/decrypt permissions for service identities in the project
- membership in VPC SC standard or bridge perimeters
- billing budgets (TODO)
- per-project IaC configuration (TODO)

The factory is implemented as a thin wrapping layer, so that no "magic" or hidden side effects are implemented in code, and debugging or integration of new features are simple.

The code is meant to be executed by a high level service accounts with powerful permissions:

- Shared VPC connection if service project attachment is desired
- project creation on the nodes (folder or org) where projects will be defined

## Leveraging data defaults, merges, optionals

In addition to the YAML-based project configurations, the factory accepts three additional sets of inputs via Terraform variables:

- the `data_defaults` variable allows defining defaults for specific project attributes, which are only used if the attributes are not passed in via YAML
- the `data_overrides` variable works similarly to defaults, but the values specified here take precedence over those in YAML files
- the `data_merges` variable allows specifying additional values for map or set based variables, which are merged with the data coming from YAML

Some examples on where to use each of the three sets are provided below.

## Example

```hcl
module "project-factory" {
  source = "./fabric/modules/project-factory"
  # use a default billing account if none is specified via yaml
  data_defaults = {
    billing_account = "012345-67890A-ABCDEF"
  }
  # make sure the environment label and stackdriver service are always added
  data_merges = {
    labels = {
      environment = "test"
    }
    services = [
      "stackdriver.googleapis.com"
    ]
  }
  # always use this contaxt and prefix, regardless of what is in the yaml file
  data_overrides = {
    contacts = {
      "admin@example.com" = ["ALL"]
    }
    prefix = "test-pf"
  }
  # location where the yaml files are read from
  factory_data_path = "data"
}
# tftest modules=7 resources=33 files=prj-app-1,prj-app-2,prj-app-3 inventory=example.yaml
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
  - container.googleapis.com
  - storage.googleapis.com
service_accounts:
  app-1-be:
    iam_project_roles:
    - roles/logging.logWriter
    - roles/monitoring.metricWriter
  app-1-fe:
    display_name: "Test app 1 frontend."

# tftest-file id=prj-app-1 path=data/prj-app-1.yaml
```

```yaml
labels:
  app: app-2
  team: foo
parent: folders/12345678
org_policies:
  "compute.restrictSharedVpcSubnetworks":
    rules:
    - allow:
        values:
        - projects/foo-host/regions/europe-west1/subnetworks/prod-default-ew1
service_accounts:
  app-2-be: {}
services:
- compute.googleapis.com
- container.googleapis.com
- run.googleapis.com
- storage.googleapis.com
shared_vpc_service_config:
  host_project: foo-host
  service_identity_iam:
    "roles/vpcaccess.user":
    - cloudrun
    "roles/container.hostServiceAgentUser":
    - container-engine
  service_identity_subnet_iam:
    europe-west1/prod-default-ew1:
    - cloudservices
    - container-engine
  network_subnet_users:
    europe-west1/prod-default-ew1:
    - group:team-1@example.com

# tftest-file id=prj-app-2 path=data/prj-app-2.yaml
```

```yaml
parent: folders/12345678
services:
- run.googleapis.com
- storage.googleapis.com

# tftest-file id=prj-app-3 path=data/prj-app-3.yaml
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [factory_data_path](variables.tf#L91) | Path to folder with YAML project description data files. | <code>string</code> | ✓ |  |
| [data_defaults](variables.tf#L17) | Optional default values used when corresponding project data from files are missing. | <code title="object&#40;&#123;&#10;  billing_account            &#61; optional&#40;string&#41;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  parent                     &#61; optional&#40;string&#41;&#10;  prefix                     &#61; optional&#40;string&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  service_perimeter_bridges  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  service_perimeter_standard &#61; optional&#40;string&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  shared_vpc_service_config &#61; optional&#40;object&#40;&#123;&#10;    host_project                &#61; string&#10;    network_users               &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    service_identity_iam        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_identity_subnet_iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_iam_grants          &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    network_subnet_users        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, &#123; host_project &#61; null &#125;&#41;&#10;  tag_bindings &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name      &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_project_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_merges](variables.tf#L49) | Optional values that will be merged with corresponding data from files. Combines with `data_defaults`, file data, and `data_overrides`. | <code title="object&#40;&#123;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  metric_scopes              &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  service_perimeter_bridges  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name      &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_project_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_overrides](variables.tf#L69) | Optional values that override corresponding data from files. Takes precedence over file data and `data_defaults`. | <code title="object&#40;&#123;&#10;  billing_account            &#61; optional&#40;string&#41;&#10;  contacts                   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  parent                     &#61; optional&#40;string&#41;&#10;  prefix                     &#61; optional&#40;string&#41;&#10;  service_encryption_key_ids &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  service_perimeter_bridges  &#61; optional&#40;list&#40;string&#41;&#41;&#10;  service_perimeter_standard &#61; optional&#40;string&#41;&#10;  tag_bindings               &#61; optional&#40;map&#40;string&#41;&#41;&#10;  services                   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  service_accounts &#61; optional&#40;map&#40;object&#40;&#123;&#10;    display_name      &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;    iam_project_roles &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [projects](outputs.tf#L17) | Project module outputs. |  |
| [service_accounts](outputs.tf#L22) | Service account emails. |  |
<!-- END TFDOC -->

## Tests

These tests validate fixes to the project factory.

```hcl
module "project-factory" {
  source = "./fabric/modules/project-factory"
  data_defaults = {
    billing_account = "012345-67890A-ABCDEF"
  }
  data_merges = {
    labels = {
      owner = "foo"
    }
    services = [
      "compute.googleapis.com"
    ]
  }
  data_overrides = {
    prefix = "foo"
  }
  factory_data_path = "data"
}
# tftest modules=4 resources=14 files=test-0,test-1,test-2
```

```yaml
parent: folders/1234567890
services:
  - iam.googleapis.com
  - contactcenteraiplatform.googleapis.com
  - container.googleapis.com
# tftest-file id=test-0 path=data/test-0.yaml
```

```yaml
parent: folders/1234567890
services:
  - iam.googleapis.com
  - contactcenteraiplatform.googleapis.com
# tftest-file id=test-1 path=data/test-1.yaml
```

```yaml
parent: folders/1234567890
services:
  - iam.googleapis.com
  - storage.googleapis.com
# tftest-file id=test-2 path=data/test-2.yaml
```
