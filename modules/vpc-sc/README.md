# VPC Service Controls

This module offers a unified interface to manage VPC Service Controls [Access Policy](https://cloud.google.com/access-context-manager/docs/create-access-policy), [Access Levels](https://cloud.google.com/access-context-manager/docs/manage-access-levels), and [Service Perimeters](https://cloud.google.com/vpc-service-controls/docs/service-perimeters).

Given the complexity of the underlying resources, the module intentionally mimics their interfaces to make it easier to map their documentation onto its variables, and reduce the internal complexity.

If you are using [Application Default Credentials](https://cloud.google.com/sdk/gcloud/reference/auth/application-default) with Terraform and run into permissions issues, make sure to check out the recommended provider configuration in the [VPC SC resources documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_access_level).

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Access policy](#access-policy)
    - [Scoped policy](#scoped-policy)
    - [Access policy IAM](#access-policy-iam)
  - [Access levels](#access-levels)
  - [Perimeters](#perimeters)
- [Automatic Project ID to Project Number Conversion](#automatic-project-id-to-project-number-conversion)
- [Factories](#factories)
- [Notes](#notes)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
- [Tests](#tests)
<!-- END TOC -->

## Examples

### Access policy

By default, the module is configured to use an existing policy, passed in by name in the `access_policy` variable:

```hcl
module "test" {
  source        = "./fabric/modules/vpc-sc"
  access_policy = "12345678"
}
# tftest modules=0 resources=0
```

If you need the module to create the policy for you, use the `access_policy_create` variable, and set `access_policy` to `null`:

```hcl
module "test" {
  source        = "./fabric/modules/vpc-sc"
  access_policy = null
  access_policy_create = {
    parent = "organizations/123456"
    title  = "vpcsc-policy"
  }
}
# tftest modules=1 resources=1 inventory=access-policy.yaml
```

#### Scoped policy

If you need the module to create a scoped policy for you, specify 'scopes' of the policy in the `access_policy_create` variable:

```hcl
module "test" {
  source        = "./fabric/modules/vpc-sc"
  access_policy = null
  access_policy_create = {
    parent = "organizations/123456"
    title  = "vpcsc-policy"
    scopes = ["folders/456789"]
  }
}
# tftest modules=1 resources=1 inventory=scoped-access-policy.yaml
```

#### Access policy IAM

The usual IAM interface is also implemented here, and can be used with service accounts or user principals:

```hcl
module "test" {
  source        = "./fabric/modules/vpc-sc"
  access_policy = "12345678"
  iam = {
    "roles/accesscontextmanager.policyAdmin" = [
      "user:foo@example.org"
    ]
  }
}
# tftest modules=1 resources=1
```

### Access levels

As highlighted above, the `access_levels` type replicates the underlying resource structure.

```hcl
module "test" {
  source        = "./fabric/modules/vpc-sc"
  access_policy = "12345678"
  access_levels = {
    a1 = {
      conditions = [
        { members = ["user:user1@example.com"] }
      ]
    }
    a2 = {
      combining_function = "OR"
      conditions = [
        { regions = ["IT", "FR"] },
        { ip_subnetworks = ["101.101.101.0/24"] }
      ]
    }
  }
}
# tftest modules=1 resources=2 inventory=access-levels.yaml
```

### Perimeters

Perimeters are defined via `perimeters` variable, or the dedicated factory.

Perimeters by default manage all their attributes authoritatively. To have perimeter resources managed externally (e.g. from the project factory) set the perimeter-level attribute `ignore_resource_changes` at the perimeter level.

```hcl
module "test" {
  source        = "./fabric/modules/vpc-sc"
  access_policy = "12345678"
  access_levels = {
    a1 = {
      conditions = [
        { members = ["user:user1@example.com"] }
      ]
    }
    a2 = {
      conditions = [
        { members = ["user:user2@example.com"] }
      ]
    }
  }
  egress_policies = {
    # allow writing to external GCS bucket from a specific SA
    gcs-sa-foo = {
      from = {
        identities = [
          "serviceAccount:foo@myproject.iam.gserviceaccount.com"
        ]
      }
      to = {
        operations = [{
          method_selectors = ["*"]
          service_name     = "storage.googleapis.com"
        }]
        resources = ["projects/123456789"]
      }
    }
  }
  ingress_policies = {
    # allow management from external automation SA
    sa-tf-test = {
      from = {
        identities = [
          "serviceAccount:test-tf-0@myproject.iam.gserviceaccount.com",
          "serviceAccount:test-tf-1@myproject.iam.gserviceaccount.com"
        ]
        access_levels = ["*"]
      }
      to = {
        operations = [{ service_name = "*" }]
        resources  = ["*"]
      }
    }
    sa-roles = {
      from = {
        identities = [
          "serviceAccount:test-tf-2@myproject.iam.gserviceaccount.com",
        ]
        access_levels = ["*"]
      }
      to = {
        operations = [{ service_name = "*" }]
        resources  = ["*"]
        roles      = ["roles/storage.objectViewer"]
      }
    }
  }
  perimeters = {
    r1 = {
      status = {
        access_levels       = ["a1", "a2"]
        resources           = ["projects/1111", "projects/2222"]
        restricted_services = ["storage.googleapis.com"]
        egress_policies     = ["gcs-sa-foo"]
        ingress_policies    = ["sa-tf-test", "sa-roles"]
        vpc_accessible_services = {
          allowed_services   = ["storage.googleapis.com"]
          enable_restriction = true
        }
      }
    }
  }
}
# tftest modules=1 resources=3 inventory=regular.yaml
```

## Automatic Project ID to Project Number Conversion

As a convenience, this module can optionally convert project IDs to project numbers. Set `var.project_id_search_scope` to a folder or organization ID to define the search scope.

The caller must have `cloudasset.assets.searchAllResources` permission to perform the search. Roles like `roles/accesscontextmanager.policyAdmin`, `roles/cloudasset.viewer`, or `roles/viewer` grant this.

```hcl
module "vpc-sc" {
  source                  = "./fabric/modules/vpc-sc"
  project_id_search_scope = var.org_id
  access_policy = "12345678"
  ingress_policies = {
    i1 = {
      from = {
        identities = [
          "serviceAccount:foo@myproject.iam.gserviceaccount.com"
        ]
        resources = ["projects/my-source-project"]
      }
      to = {
        operations = [{
          method_selectors = ["*"]
          service_name     = "storage.googleapis.com"
        }]
        resources = ["projects/my-destionation-project"]
      }
    }
  }
  perimeters = {
    p = {
      spec = {
        ingress_policies = ["i1"]
        resources        = ["projects/my-destionation-project"]
      }
      use_explicit_dry_run_spec = true
    }
  }
}
# tftest skip because uses data sources
```

## Factories

This module implements support for four distinct factories, used to create and manage perimeters, access levels, egress policies, and ingress policies via YAML files.

JSON Schema files for each factory object are available in the [`schemas`](./schemas/) folder, and can be used to validate input YAML data with [`validate-yaml`](https://github.com/gerald1248/validate-yaml) or any of the available tools and libraries.

3Note that the factory configuration points to folders, where each file represents one resource.

```hcl
module "test" {
  source        = "./fabric/modules/vpc-sc"
  access_policy = "12345678"
  context = {
    resource_sets = {
      foo_projects = ["projects/321", "projects/654"]
    }
  }
  factories_config = {
    access_levels    = "data/access-levels"
    egress_policies  = "data/egress-policies"
    ingress_policies = "data/ingress-policies"
    perimeters       = "data/perimeters"
  }
}
# tftest modules=1 resources=3 files=p1,a1,a2,e1,i1,i2 inventory=factory.yaml
```

```yaml
description: Main perimeter
status:
  access_levels:
    - "geo-it"
    - "identity-user1"
  resources:
    - "projects/1111"
    - "projects/2222"
  restricted_services:
    - "storage.googleapis.com"
  egress_policies:
    - "gcs-sa-foo"
  ingress_policies:
    - "sa-tf-test-geo"
    - "sa-tf-test"
  vpc_accessible_services:
    allowed_services:
      - "storage.googleapis.com"
    enable_restriction: yes

# tftest-file id=p1 path=data/perimeters/perimeter-north.yaml schema=perimeters.schema.json
```

```yaml
description: "Main perimeter"
status:
  access_levels:
    - geo-it
    - identity-user1
  resources:
    - projects/1111
    - projects/2222
  restricted_services:
    - storage.googleapis.com
  egress_policies:
    - gcs-sa-foo
  ingress_policies:
    - sa-tf-test-geo
    - sa-tf-test
  vpc_accessible_services:
    allowed_services:
      - storage.googleapis.com
    enable_restriction: true
# tftest-file id=p1 path=data/perimeters/perimeter-north.yaml schema=perimeters.schema.json
```

```yaml
conditions:
  - members:
    - user:user1@example.com
# tftest-file id=a1 path=data/access-levels/identity-user1.yaml schema=access-level.schema.json
```

```yaml
conditions:
  - regions:
      - IT
# tftest-file id=a2 path=data/access-levels/geo-it.yaml schema=access-level.schema.json
```

```yaml
from:
  identities:
    - serviceAccount:foo@myproject.iam.gserviceaccount.com
    - serviceAccount:bar@myproject.iam.gserviceaccount.com
to:
  operations:
    - method_selectors:
        - "*"
      service_name: storage.googleapis.com
  resources:
    - projects/123456789

# tftest-file id=e1 path=data/egress-policies/gcs-sa-foo.yaml schema=egress-policy.schema.json
```

```yaml
from:
  access_levels:
    - "*"
  identities:
    - serviceAccount:test-tf-0@myproject.iam.gserviceaccount.com
    - serviceAccount:test-tf-1@myproject.iam.gserviceaccount.com
to:
  operations:
    - service_name: compute.googleapis.com
      method_selectors:
        - ProjectsService.Get
        - RegionsService.Get
  resources:
    - "*"
# tftest-file id=i1 path=data/ingress-policies/sa-tf-test.yaml schema=ingress-policy.schema.json
```

```yaml
from:
  access_levels:
    - geo-it
  identities:
    - serviceAccount:test-tf@myproject.iam.gserviceaccount.com
to:
  operations:
    - service_name: "*"
  resources:
    - projects/1234567890
    - $resource_sets:foo_projects
# tftest-file id=i2 path=data/ingress-policies/sa-tf-test-geo.yaml schema=ingress-policy.schema.json
```

## Notes

- To remove an access level, first remove the binding between perimeter and the access level in `status` and/or `spec` without removing the access level itself. Once you have run `terraform apply`, you'll then be able to remove the access level and run `terraform apply` again.

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | resources |
|---|---|---|
| [access-levels.tf](./access-levels.tf) | Access level resources. | <code>google_access_context_manager_access_level</code> |
| [factory.tf](./factory.tf) | None |  |
| [iam.tf](./iam.tf) | IAM bindings | <code>google_access_context_manager_access_policy_iam_binding</code> · <code>google_access_context_manager_access_policy_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_access_context_manager_access_policy</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [perimeters-additive.tf](./perimeters-additive.tf) | Regular service perimeter resources which ignore resource changes. | <code>google_access_context_manager_service_perimeter</code> |
| [perimeters.tf](./perimeters.tf) | Regular service perimeter resources. | <code>google_access_context_manager_service_perimeter</code> |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [access_policy](variables.tf#L68) | Access Policy name, set to null if creating one. | <code>string</code> | ✓ |  |
| [access_levels](variables.tf#L17) | Access level definitions. | <code title="map&#40;object&#40;&#123;&#10;  combining_function &#61; optional&#40;string&#41;&#10;  conditions &#61; optional&#40;list&#40;object&#40;&#123;&#10;    device_policy &#61; optional&#40;object&#40;&#123;&#10;      allowed_device_management_levels &#61; optional&#40;list&#40;string&#41;&#41;&#10;      allowed_encryption_statuses      &#61; optional&#40;list&#40;string&#41;&#41;&#10;      require_admin_approval           &#61; bool&#10;      require_corp_owned               &#61; bool&#10;      require_screen_lock              &#61; optional&#40;bool&#41;&#10;      os_constraints &#61; optional&#40;list&#40;object&#40;&#123;&#10;        os_type                    &#61; string&#10;        minimum_version            &#61; optional&#40;string&#41;&#10;        require_verified_chrome_os &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    ip_subnetworks         &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    members                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    negate                 &#61; optional&#40;bool&#41;&#10;    regions                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    required_access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    vpc_subnets            &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  description &#61; optional&#40;string&#41;&#10;  title       &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [access_policy_create](variables.tf#L73) | Access Policy configuration, fill in to create. Parent is in 'organizations/123456' format, scopes are in 'folders/456789' or 'projects/project_id' format. | <code title="object&#40;&#123;&#10;  parent &#61; string&#10;  title  &#61; string&#10;  scopes &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [context](variables.tf#L83) | External context used in replacements. | <code title="object&#40;&#123;&#10;  condition_vars  &#61; optional&#40;map&#40;map&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_principals  &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  identity_sets   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  project_numbers &#61; optional&#40;map&#40;number&#41;, &#123;&#125;&#41;&#10;  resource_sets   &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  service_sets    &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [egress_policies](variables.tf#L97) | Egress policy definitions that can be referenced in perimeters. | <code title="map&#40;object&#40;&#123;&#10;  title &#61; optional&#40;string&#41;&#10;  from &#61; object&#40;&#123;&#10;    access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    identity_type &#61; optional&#40;string&#41;&#10;    identities    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#10;  to &#61; object&#40;&#123;&#10;    external_resources &#61; optional&#40;list&#40;string&#41;&#41;&#10;    operations &#61; optional&#40;list&#40;object&#40;&#123;&#10;      method_selectors     &#61; optional&#40;list&#40;string&#41;&#41;&#10;      permission_selectors &#61; optional&#40;list&#40;string&#41;&#41;&#10;      service_name         &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    resources &#61; optional&#40;list&#40;string&#41;&#41;&#10;    roles     &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [factories_config](variables.tf#L140) | Paths to folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  access_levels    &#61; optional&#40;string&#41;&#10;  egress_policies  &#61; optional&#40;string&#41;&#10;  ingress_policies &#61; optional&#40;string&#41;&#10;  perimeters       &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L152) | IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables.tf#L158) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables.tf#L173) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ingress_policies](variables.tf#L188) | Ingress policy definitions that can be referenced in perimeters. | <code title="map&#40;object&#40;&#123;&#10;  title &#61; optional&#40;string&#41;&#10;  from &#61; object&#40;&#123;&#10;    access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    identity_type &#61; optional&#40;string&#41;&#10;    identities    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#10;  to &#61; object&#40;&#123;&#10;    operations &#61; optional&#40;list&#40;object&#40;&#123;&#10;      method_selectors     &#61; optional&#40;list&#40;string&#41;&#41;&#10;      permission_selectors &#61; optional&#40;list&#40;string&#41;&#41;&#10;      service_name         &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    resources &#61; optional&#40;list&#40;string&#41;&#41;&#10;    roles     &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [perimeters](variables.tf#L230) | Regular service perimeters. | <code title="map&#40;object&#40;&#123;&#10;  description               &#61; optional&#40;string&#41;&#10;  ignore_resource_changes   &#61; optional&#40;bool, false&#41;&#10;  title                     &#61; optional&#40;string&#41;&#10;  use_explicit_dry_run_spec &#61; optional&#40;bool, false&#41;&#10;  spec &#61; optional&#40;object&#40;&#123;&#10;    access_levels       &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    egress_policies     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    ingress_policies    &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    restricted_services &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    resources           &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    vpc_accessible_services &#61; optional&#40;object&#40;&#123;&#10;      allowed_services   &#61; list&#40;string&#41;&#10;      enable_restriction &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  status &#61; optional&#40;object&#40;&#123;&#10;    access_levels       &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    egress_policies     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    ingress_policies    &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    resources           &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    restricted_services &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    vpc_accessible_services &#61; optional&#40;object&#40;&#123;&#10;      allowed_services   &#61; list&#40;string&#41;&#10;      enable_restriction &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [project_id_search_scope](variables.tf#L264) | Set this to an organization or folder ID to use Cloud Asset Inventory to automatically translate project ids to numbers. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [access_level_names](outputs.tf#L17) | Access level resources. |  |
| [access_levels](outputs.tf#L25) | Access level resources. |  |
| [access_policy](outputs.tf#L30) | Access policy resource, if autocreated. |  |
| [access_policy_name](outputs.tf#L37) | Access policy name. |  |
| [id](outputs.tf#L42) | Fully qualified access policy id. |  |
| [perimeters](outputs.tf#L47) | Regular service perimeter resources. |  |
<!-- END TFDOC -->
## Tests

```hcl
module "test" {
  source        = "./fabric/modules/vpc-sc"
  access_policy = "12345678"
  factories_config = {
    access_levels    = "data/access-levels"
    egress_policies  = "data/egress-policies"
    ingress_policies = "data/ingress-policies"
  }
  ingress_policies = {
    variable-policy = {
      from = {
        identities = [
          "serviceAccount:sa-0@myproject.iam.gserviceaccount.com"
        ]
        access_levels = ["*"]
      }
      to = {
        operations = [{ service_name = "*" }]
        resources  = ["*"]
      }
    }
  }
  perimeters = {
    default = {
      status = {
        access_levels    = ["geo-it"]
        resources        = ["projects/1111"]
        egress_policies  = ["factory-egress-policy"]
        ingress_policies = ["variable-policy", "factory-ingress-policy"]
      }
    }
  }
}
# tftest modules=1 resources=2 files=t1a1,t1i1,t1e1
```

```yaml
conditions:
  - regions:
      - IT
# tftest-file id=t1a1 path=data/access-levels/geo-it.yaml schema=access-level.schema.json
```

```yaml
from:
  access_levels:
    - geo-it
  identity_type: ANY_IDENTITY
to:
  operations:
    - service_name: "*"
  resources:
    - projects/1234567890
# tftest-file id=t1i1 path=data/ingress-policies/factory-ingress-policy.yaml schema=ingress-policy.schema.json
```

```yaml
from:
  identity_type: ANY_IDENTITY
to:
  operations:
    - service_name: "*"
  resources:
    - "*"
# tftest-file id=t1e1 path=data/egress-policies/factory-egress-policy.yaml schema=egress-policy.schema.json
```
