# VPC Service Controls

This module offers a unified interface to manage VPC Service Controls [Access Policy](https://cloud.google.com/access-context-manager/docs/create-access-policy), [Access Levels](https://cloud.google.com/access-context-manager/docs/manage-access-levels), and [Service Perimeters](https://cloud.google.com/vpc-service-controls/docs/service-perimeters).

Given the complexity of the underlying resources, the module intentionally mimics their interfaces to make it easier to map their documentation onto its variables, and reduce the internal complexity. The tradeoff is some verbosity, and a very complex type for the `service_perimeters_regular` variable (while [optional type attributes](https://www.terraform.io/language/expressions/type-constraints#experimental-optional-object-type-attributes) are still an experiment).

If you are using [Application Default Credentials](https://cloud.google.com/sdk/gcloud/reference/auth/application-default) with Terraform and run into permissions issues, make sure to check out the recommended provider configuration in the [VPC SC resources documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_access_level).

## Examples

### Access policy

By default, the module is configured to use an existing policy, passed in by name in the `access_policy` variable:

```hcl
module "test" {
  source        = "./modules/vpc-sc"
  access_policy = "accessPolicies/12345678"
}
# tftest:modules=0:resources=0
```

If you need the module to create the policy for you, use the `access_policy_create` variable, and set `access_policy` to `null`:

```hcl
module "test" {
  source        = "./modules/vpc-sc"
  access_policy = null
  access_policy_create = {
    parent = "organizations/123456"
    title  = "vpcsc-policy"
  }
}
# tftest:modules=1:resources=1
```

### Access levels

As highlighted above, the `access_levels` type replicates the underlying resource structure.

```hcl
module "test" {
  source        = "./modules/vpc-sc"
  access_policy = "accessPolicies/12345678"
  access_levels = {
    a1 = {
      combining_function = null
      conditions = [{
        members       = ["user:ludomagno@google.com"],
        device_policy = null, ip_subnetworks = null, negate = null,
        regions       = null, required_access_levels = null
      }]
    }
    a2 = {
      combining_function = "OR"
      conditions = [{
        regions       = ["IT", "FR"],
        device_policy = null, ip_subnetworks = null, members = null,
        negate        = null, required_access_levels = null
      },{
        ip_subnetworks = ["101.101.101.0/24"],
        device_policy  = null, members = null, negate = null,
        regions        = null, required_access_levels = null
      }]
    }
  }
}
# tftest:modules=1:resources=2
```

### Service perimeters

Bridge and regular service perimeters use two separate variables, as bridge perimeters only accept a limited number of arguments, and can leverage a much simpler interface.

The regular perimeters variable exposes all the complexity of the underlying resource, use [its documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter) as a reference about the possible values and configurations.

If you need to refer to access levels created by the same module in regular service perimeters, simply use the module's outputs in the provided variables. The example below shows how to do this in practice.

Resources for both perimeters have a `lifecycle` block that ignores changes to `spec` and `status` resources (projects), to allow using the additive resource `google_access_context_manager_service_perimeter_resource` at project creation. If this is not needed, the `lifecycle` blocks can be safely commented in the code.

#### Bridge type

```hcl
module "test" {
  source        = "./modules/vpc-sc"
  access_policy = "accessPolicies/12345678"
  service_perimeters_bridge = {
    b1 = {
      status_resources          = ["projects/111110", "projects/111111"]
      spec_resources            = null
      use_explicit_dry_run_spec = false
    }
    b2 = {
      status_resources          = ["projects/222220", "projects/222221"]
      spec_resources            = ["projects/222220", "projects/222221"]
      use_explicit_dry_run_spec = true
    }
  }
}
# tftest:modules=1:resources=2
```

#### Regular type

```hcl
module "test" {
  source        = "./modules/vpc-sc"
  access_policy = "accessPolicies/12345678"
  access_levels = {
    a1 = {
      combining_function = null
      conditions = [{
        members       = ["user:ludomagno@google.com"],
        device_policy = null, ip_subnetworks = null, negate = null,
        regions       = null, required_access_levels = null
      }]
    }
  }
  service_perimeters_regular = {
    r1 = {
      spec = null
      status = {
        access_levels       = [module.test.access_level_names["a1"]]
        resources           = ["projects/11111", "projects/111111"]
        restricted_services = ["storage.googleapis.com"]
        egress_policies     = null
        ingress_policies    = null
        vpc_accessible_services = {
          allowed_services   = ["compute.googleapis.com"]
          enable_restriction = true
        }
      }
      use_explicit_dry_run_spec = false
    }
  }
}
# tftest:modules=1:resources=2
```

## TODO

- [ ] implement support for the  `google_access_context_manager_gcp_user_access_binding` resource




<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| access_policy | Access Policy name, leave null to use auto-created one. | <code>string</code> | ✓ |  |
| access_levels | Map of access levels in name => [conditions] format. | <code title="map&#40;object&#40;&#123;&#10;  combining_function &#61; string&#10;  conditions &#61; list&#40;object&#40;&#123;&#10;    device_policy &#61; object&#40;&#123;&#10;      require_screen_lock              &#61; bool&#10;      allowed_encryption_statuses      &#61; list&#40;string&#41;&#10;      allowed_device_management_levels &#61; list&#40;string&#41;&#10;      os_constraints &#61; list&#40;object&#40;&#123;&#10;        minimum_version            &#61; string&#10;        os_type                    &#61; string&#10;        require_verified_chrome_os &#61; bool&#10;      &#125;&#41;&#41;&#10;      require_admin_approval &#61; bool&#10;      require_corp_owned     &#61; bool&#10;    &#125;&#41;&#10;    ip_subnetworks         &#61; list&#40;string&#41;&#10;    members                &#61; list&#40;string&#41;&#10;    negate                 &#61; bool&#10;    regions                &#61; list&#40;string&#41;&#10;    required_access_levels &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| access_policy_create | Access Policy configuration, fill in to create. Parent is in 'organizations/123456' format. | <code title="object&#40;&#123;&#10;  parent &#61; string&#10;  title  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| service_perimeters_bridge | Bridge service perimeters. | <code title="map&#40;object&#40;&#123;&#10;  spec_resources            &#61; list&#40;string&#41;&#10;  status_resources          &#61; list&#40;string&#41;&#10;  use_explicit_dry_run_spec &#61; bool&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| service_perimeters_regular | Regular service perimeters. | <code title="map&#40;object&#40;&#123;&#10;  spec &#61; object&#40;&#123;&#10;    access_levels       &#61; list&#40;string&#41;&#10;    resources           &#61; list&#40;string&#41;&#10;    restricted_services &#61; list&#40;string&#41;&#10;    egress_policies &#61; list&#40;object&#40;&#123;&#10;      egress_from &#61; object&#40;&#123;&#10;        identity_type &#61; string&#10;        identities    &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;      egress_to &#61; object&#40;&#123;&#10;        operations &#61; list&#40;object&#40;&#123;&#10;          method_selectors &#61; list&#40;string&#41;&#10;          service_name     &#61; string&#10;        &#125;&#41;&#41;&#10;        resources &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;&#10;    ingress_policies &#61; list&#40;object&#40;&#123;&#10;      ingress_from &#61; object&#40;&#123;&#10;        identity_type        &#61; string&#10;        identities           &#61; list&#40;string&#41;&#10;        source_access_levels &#61; list&#40;string&#41;&#10;        source_resources     &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;      ingress_to &#61; object&#40;&#123;&#10;        operations &#61; list&#40;object&#40;&#123;&#10;          method_selectors &#61; list&#40;string&#41;&#10;          service_name     &#61; string&#10;        &#125;&#41;&#41;&#10;        resources &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;&#10;    vpc_accessible_services &#61; object&#40;&#123;&#10;      allowed_services   &#61; list&#40;string&#41;&#10;      enable_restriction &#61; bool&#10;    &#125;&#41;&#10;  &#125;&#41;&#10;  status &#61; object&#40;&#123;&#10;    access_levels       &#61; list&#40;string&#41;&#10;    resources           &#61; list&#40;string&#41;&#10;    restricted_services &#61; list&#40;string&#41;&#10;    egress_policies &#61; list&#40;object&#40;&#123;&#10;      egress_from &#61; object&#40;&#123;&#10;        identity_type &#61; string&#10;        identities    &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;      egress_to &#61; object&#40;&#123;&#10;        operations &#61; list&#40;object&#40;&#123;&#10;          method_selectors &#61; list&#40;string&#41;&#10;          service_name     &#61; string&#10;        &#125;&#41;&#41;&#10;        resources &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;&#10;    ingress_policies &#61; list&#40;object&#40;&#123;&#10;      ingress_from &#61; object&#40;&#123;&#10;        identity_type        &#61; string&#10;        identities           &#61; list&#40;string&#41;&#10;        source_access_levels &#61; list&#40;string&#41;&#10;        source_resources     &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;      ingress_to &#61; object&#40;&#123;&#10;        operations &#61; list&#40;object&#40;&#123;&#10;          method_selectors &#61; list&#40;string&#41;&#10;          service_name     &#61; string&#10;        &#125;&#41;&#41;&#10;        resources &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;&#10;    vpc_accessible_services &#61; object&#40;&#123;&#10;      allowed_services   &#61; list&#40;string&#41;&#10;      enable_restriction &#61; bool&#10;    &#125;&#41;&#10;  &#125;&#41;&#10;  use_explicit_dry_run_spec &#61; bool&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| access_level_names | Access level resources. |  |
| access_levels | Access level resources. |  |
| access_policy | Access policy resource, if autocreated. |  |
| access_policy_name | Access policy name. |  |
| service_perimeters_bridge | Bridge service perimeter resources. |  |
| service_perimeters_regular | Regular service perimeter resources. |  |

<!-- END TFDOC -->



