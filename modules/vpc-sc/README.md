# VPC Service Controls

This module offers a unified interface to manage VPC Service Controls [Access Policy](https://cloud.google.com/access-context-manager/docs/create-access-policy), [Access Levels](https://cloud.google.com/access-context-manager/docs/manage-access-levels), and [Service Perimeters](https://cloud.google.com/vpc-service-controls/docs/service-perimeters).

Given the complexity of the underlying resources, the module intentionally mimics their interfaces to make it easier to map their documentation onto its variables, and reduce the internal complexity.

If you are using [Application Default Credentials](https://cloud.google.com/sdk/gcloud/reference/auth/application-default) with Terraform and run into permissions issues, make sure to check out the recommended provider configuration in the [VPC SC resources documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_access_level).

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
# tftest modules=1 resources=2
```

### Service perimeters

Bridge and regular service perimeters use two separate variables, as bridge perimeters only accept a limited number of arguments, and can leverage a much simpler interface.

The regular perimeters variable exposes all the complexity of the underlying resource, use [its documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter) as a reference about the possible values and configurations.

If you need to refer to access levels created by the same module in regular service perimeters, you can either use the module's outputs in the provided variables, or the key used to identify the relevant access level. The example below shows how to do this in practice.

/*
Resources for both perimeters have a `lifecycle` block that ignores changes to `spec` and `status` resources (projects), to allow using the additive resource `google_access_context_manager_service_perimeter_resource` at project creation. If this is not needed, the `lifecycle` blocks can be safely commented in the code.
*/

#### Bridge type

```hcl
module "test" {
  source        = "./fabric/modules/vpc-sc"
  access_policy = "12345678"
  service_perimeters_bridge = {
    b1 = {
      status_resources = ["projects/111110", "projects/111111"]
    }
    b2 = {
      spec_resources            = ["projects/222220", "projects/222221"]
      use_explicit_dry_run_spec = true
    }
  }
}
# tftest modules=1 resources=2
```

#### Regular type

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
          service_name = "storage.googleapis.com"
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
          "serviceAccount:test-tf@myproject.iam.gserviceaccount.com",
        ],
        source_access_levels = ["*"]
      }
      to = {
        operations = [{ service_name = "*" }]
        resources  = ["*"]
      }
    }
  }
  service_perimeters_regular = {
    r1 = {
      status = {
        access_levels       = ["a1", "a2"]
        resources           = ["projects/11111", "projects/111111"]
        restricted_services = ["storage.googleapis.com"]
        egress_policies     = ["gcs-sa-foo"]
        ingress_policies    = ["sa-tf-test"]
        vpc_accessible_services = {
          allowed_services   = ["storage.googleapis.com"]
          enable_restriction = true
        }
      }
    }
  }
}
# tftest modules=1 resources=3
```

## Notes

- To remove an access level, first remove the binding between perimeter and the access level in `status` and/or `spec` without removing the access level itself. Once you have run `terraform apply`, you'll then be able to remove the access level and run `terraform apply` again.

## TODO

- [ ] implement support for the  `google_access_context_manager_gcp_user_access_binding` resource

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->

## Files

| name | description | resources |
|---|---|---|
| [access-levels.tf](./access-levels.tf) | Access level resources. | <code>google_access_context_manager_access_level</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_access_context_manager_access_policy</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [service-perimeters-bridge.tf](./service-perimeters-bridge.tf) | Bridge service perimeter resources. | <code>google_access_context_manager_service_perimeter</code> |
| [service-perimeters-regular.tf](./service-perimeters-regular.tf) | Regular service perimeter resources. | <code>google_access_context_manager_service_perimeter</code> |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [access_policy](variables.tf#L56) | Access Policy name, set to null if creating one. | <code>string</code> | ✓ |  |
| [access_levels](variables.tf#L17) | Access level definitions. | <code title="map&#40;object&#40;&#123;&#10;  combining_function &#61; optional&#40;string&#41;&#10;  conditions &#61; optional&#40;list&#40;object&#40;&#123;&#10;    device_policy &#61; optional&#40;object&#40;&#123;&#10;      allowed_device_management_levels &#61; optional&#40;list&#40;string&#41;&#41;&#10;      allowed_encryption_statuses      &#61; optional&#40;list&#40;string&#41;&#41;&#10;      require_admin_approval           &#61; bool&#10;      require_corp_owned               &#61; bool&#10;      require_screen_lock              &#61; optional&#40;bool&#41;&#10;      os_constraints &#61; optional&#40;list&#40;object&#40;&#123;&#10;        os_type                    &#61; string&#10;        minimum_version            &#61; optional&#40;string&#41;&#10;        require_verified_chrome_os &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    ip_subnetworks         &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    members                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    negate                 &#61; optional&#40;bool&#41;&#10;    regions                &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    required_access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  description &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [access_policy_create](variables.tf#L61) | Access Policy configuration, fill in to create. Parent is in 'organizations/123456' format. | <code title="object&#40;&#123;&#10;  parent &#61; string&#10;  title  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [egress_policies](variables.tf#L70) | Egress policy definitions that can be referenced in perimeters. | <code title="map&#40;object&#40;&#123;&#10;  from &#61; object&#40;&#123;&#10;    identity_type &#61; optional&#40;string, &#34;ANY_IDENTITY&#34;&#41;&#10;    identities    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#10;  to &#61; object&#40;&#123;&#10;    operations &#61; optional&#40;list&#40;object&#40;&#123;&#10;      method_selectors &#61; optional&#40;list&#40;string&#41;&#41;&#10;      service_name     &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    resources              &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resource_type_external &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ingress_policies](variables.tf#L99) | Ingress policy definitions that can be referenced in perimeters. | <code title="map&#40;object&#40;&#123;&#10;  from &#61; object&#40;&#123;&#10;    access_levels &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    identity_type &#61; optional&#40;string&#41;&#10;    identities    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources     &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#10;  to &#61; object&#40;&#123;&#10;    operations &#61; optional&#40;list&#40;object&#40;&#123;&#10;      method_selectors &#61; optional&#40;list&#40;string&#41;&#41;&#10;      service_name     &#61; string&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;    resources &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_perimeters_bridge](variables.tf#L130) | Bridge service perimeters. | <code title="map&#40;object&#40;&#123;&#10;  spec_resources            &#61; optional&#40;list&#40;string&#41;&#41;&#10;  status_resources          &#61; optional&#40;list&#40;string&#41;&#41;&#10;  use_explicit_dry_run_spec &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_perimeters_regular](variables.tf#L140) | Regular service perimeters. | <code title="map&#40;object&#40;&#123;&#10;  spec &#61; optional&#40;object&#40;&#123;&#10;    access_levels       &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources           &#61; optional&#40;list&#40;string&#41;&#41;&#10;    restricted_services &#61; optional&#40;list&#40;string&#41;&#41;&#10;    egress_policies     &#61; optional&#40;list&#40;string&#41;&#41;&#10;    ingress_policies    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    vpc_accessible_services &#61; optional&#40;object&#40;&#123;&#10;      allowed_services   &#61; list&#40;string&#41;&#10;      enable_restriction &#61; bool&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  status &#61; optional&#40;object&#40;&#123;&#10;    access_levels       &#61; optional&#40;list&#40;string&#41;&#41;&#10;    resources           &#61; optional&#40;list&#40;string&#41;&#41;&#10;    restricted_services &#61; optional&#40;list&#40;string&#41;&#41;&#10;    egress_policies     &#61; optional&#40;list&#40;string&#41;&#41;&#10;    ingress_policies    &#61; optional&#40;list&#40;string&#41;&#41;&#10;    vpc_accessible_services &#61; optional&#40;object&#40;&#123;&#10;      allowed_services   &#61; list&#40;string&#41;&#10;      enable_restriction &#61; bool&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  use_explicit_dry_run_spec &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [access_level_names](outputs.tf#L17) | Access level resources. |  |
| [access_levels](outputs.tf#L25) | Access level resources. |  |
| [access_policy](outputs.tf#L30) | Access policy resource, if autocreated. |  |
| [access_policy_name](outputs.tf#L35) | Access policy name. |  |
| [service_perimeters_bridge](outputs.tf#L40) | Bridge service perimeter resources. |  |
| [service_perimeters_regular](outputs.tf#L45) | Regular service perimeter resources. |  |

<!-- END TFDOC -->
