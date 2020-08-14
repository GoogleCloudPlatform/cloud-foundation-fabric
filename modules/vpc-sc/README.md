# VPC Service Control Module

This module allows managing VPC Service Control (VPC-SC) properties:

- [Access Policy](https://cloud.google.com/access-context-manager/docs/create-access-policy)
- [Access Levels](https://cloud.google.com/access-context-manager/docs/manage-access-levels)
- [VPC-SC Perimeters](https://cloud.google.com/vpc-service-controls/docs/service-perimeters)

The Use of this module requires credentials with the [correct permissions](https://cloud.google.com/access-context-manager/docs/access-control) to use Access Context Manager.

## Example VCP-SC standard perimeter

```hcl
module "vpc-sc" {
  source      = "../../modules/vpc-sc"
  org_id      = 1234567890
  access_policy_title = "My Access Policy"
  access_levels = {
    my_trusted_proxy = {  
      combining_function = "AND"
      conditions         = [{
        ip_subnetworks   = ["85.85.85.52/32"]
        members          = []
        negate           = false
      }]
    }
  }
  access_level_perimeters = {
    my_trusted_proxy  = ["perimeter"]
  } 
  perimeters = { 
    perimeter = {
      type                = "PERIMETER_TYPE_REGULAR"
      dry_run_config      = null
      enforced_config     = {
      restricted_services     = ["storage.googleapis.com"]
      vpc_accessible_services = ["storage.googleapis.com"]
      }
    }
  }
  perimeter_projects = {
    perimeter = {
      enforced = [111111111,222222222]
    }
  }
}
```

## Example VCP-SC standard perimeter with one service and one project in dry run mode
```hcl
module "vpc-sc" {
  source      = "../../modules/vpc-sc"
  org_id      = 1234567890
  access_policy_title = "My Access Policy"
  access_levels = {
    my_trusted_proxy = {  
      combining_function = "AND"
      conditions         = [{
        ip_subnetworks   = ["85.85.85.52/32"]
        members          = []
        negate           = false
      }]
    }
  }
  access_level_perimeters = {
    enforced = {
      my_trusted_proxy  = ["perimeter"]
    }
  } 
  perimeters = { 
    perimeter = {
      type                = "PERIMETER_TYPE_REGULAR"
      dry_run_config      = {
        restricted_services     = ["storage.googleapis.com", "bigquery.googleapis.com"]
        vpc_accessible_services = ["storage.googleapis.com", "bigquery.googleapis.com"]
      }
      enforced_config     = {
      restricted_services     = ["storage.googleapis.com"]
      vpc_accessible_services = ["storage.googleapis.com"]
      }
    }
  }
  perimeter_projects = {
    perimeter = {
      enforced = [111111111,222222222]
      dry_run  = [333333333]
    }
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| access_policy_title | Access Policy title to be created. | <code title="">string</code> | ✓ |  |
| org_id | Organization id in nnnnnn format. | <code title="">number</code> | ✓ |  |
| *access_level_perimeters* | Enforced mode -> Access Level -> Perimeters mapping. Enforced mode can be 'enforced' or 'dry_run' | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *access_levels* | Access Levels. | <code title="map&#40;object&#40;&#123;&#10;combining_function &#61; string&#10;conditions &#61; list&#40;object&#40;&#123;&#10;ip_subnetworks &#61; list&#40;string&#41;&#10;members        &#61; list&#40;string&#41;&#10;negate         &#61; string&#10;&#125;&#41;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *perimeter_projects* | Perimeter -> Enforced Mode -> Projects Number mapping. Enforced mode can be 'enforced' or 'dry_run'. | <code title="map&#40;map&#40;list&#40;number&#41;&#41;&#41;">map(map(list(number)))</code> |  | <code title="">{}</code> |
| *perimeters* | Set of Perimeters. | <code title="map&#40;object&#40;&#123;&#10;type &#61; string&#10;dry_run_config &#61; object&#40;&#123;&#10;restricted_services     &#61; list&#40;string&#41;&#10;vpc_accessible_services &#61; list&#40;string&#41;&#10;&#125;&#41;&#10;enforced_config &#61; object&#40;&#123;&#10;restricted_services     &#61; list&#40;string&#41;&#10;vpc_accessible_services &#61; list&#40;string&#41;&#10;&#125;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| access_levels | Access Levels. |  |
| access_policy_name | Access Policy resource |  |
| org_id | Organization id dependent on module resources. |  |
| perimeters_bridge | VPC-SC bridge perimeter resources. |  |
| perimeters_standard | VPC-SC standard perimeter resources. |  |
<!-- END TFDOC -->
