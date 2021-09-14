# VPC Service Control Module

This module allows managing VPC Service Control (VPC-SC) properties:

- [Access Policy](https://cloud.google.com/access-context-manager/docs/create-access-policy)
- [Access Levels](https://cloud.google.com/access-context-manager/docs/manage-access-levels)
- [VPC-SC Perimeters](https://cloud.google.com/vpc-service-controls/docs/service-perimeters)

The Use of this module requires credentials with the [correct permissions](https://cloud.google.com/access-context-manager/docs/access-control) to use Access Context Manager.

## Example VCP-SC standard perimeter

```hcl
module "vpc-sc" {
  source              = "./modules/vpc-sc"
  organization_id     = "organizations/112233"
  access_policy_title = "My Access Policy"
  access_levels = {
    my_trusted_proxy = {
      combining_function = "AND"
      conditions = [{
        ip_subnetworks = ["85.85.85.52/32"]
        required_access_levels = null
        members        = []
        negate         = false
        regions        = null
      }]
    }
  }
  access_level_perimeters = {
    enforced = {
      my_trusted_proxy = ["perimeter"]
    }
  }
 ingress_policies = {
   ingress_1 = {
     ingress_from = {
       identity_type = "ANY_IDENTITY"
     }
     ingress_to = {
       resources = ["*"]
       operations = {
         "storage.googleapis.com" = [{ method = "google.storage.objects.create" }]
         "bigquery.googleapis.com" = [{ method = "BigQueryStorage.ReadRows" }]
       }
     }
   }
 }
 ingress_policies_perimeters = {
   enforced = {
     ingress_1 = ["default"]
   }
 }

  egress_policies = {
    egress_1 = {
      egress_from = {
        identity_type = "ANY_USER_ACCOUNT"
      }
      egress_to = {
       resources = ["*"]
       operations = {
         "storage.googleapis.com"  = [{ method = "google.storage.objects.create" }],
         "bigquery.googleapis.com" = [{ method = "BigQueryStorage.ReadRows" },{ method = "TableService.ListTables" }, { permission = "bigquery.jobs.get" }]
       }
      }
    }
  }  
  egress_policies_perimeters = {
    enforced = {
      egress_1 = ["perimeter"]
    }  
  }  
  perimeters = {
    perimeter = {
      type           = "PERIMETER_TYPE_REGULAR"
      dry_run_config = null
      enforced_config = {
        restricted_services     = ["storage.googleapis.com"]
        vpc_accessible_services = ["storage.googleapis.com"]
      }
    }
  }
  perimeter_projects = {
    perimeter = {
      enforced = [111111111, 222222222]
    }
  }
}
# tftest:modules=1:resources=3
```

## Example VCP-SC standard perimeter with one service and one project in dry run mode
```hcl
module "vpc-sc" {
  source              = "./modules/vpc-sc"
  organization_id     = "organizations/112233"
  access_policy_title = "My Access Policy"
  access_levels = {
    my_trusted_proxy = {
      combining_function = "AND"
      conditions = [{
        ip_subnetworks = ["85.85.85.52/32"]
        required_access_levels = null
        members        = []
        negate         = false
        regions        = null
      }]
    }
  }
  access_level_perimeters = {
    enforced = {
      my_trusted_proxy = ["perimeter"]
    }
  }
  perimeters = {
    perimeter = {
      type = "PERIMETER_TYPE_REGULAR"
      dry_run_config = {
        restricted_services     = ["storage.googleapis.com", "bigquery.googleapis.com"]
        vpc_accessible_services = ["storage.googleapis.com", "bigquery.googleapis.com"]
      }
      enforced_config = {
        restricted_services     = ["storage.googleapis.com"]
        vpc_accessible_services = ["storage.googleapis.com"]
      }
    }
  }
  perimeter_projects = {
    perimeter = {
      enforced = [111111111, 222222222]
      dry_run  = [333333333]
    }
  }
}
# tftest:modules=1:resources=3
```

## Example VCP-SC standard perimeter with one service and one project in dry run mode in a Organization with an already existent access policy
```hcl
module "vpc-sc-first" {
  source              = "./modules/vpc-sc"
  organization_id     = "organizations/112233"
  access_policy_create = false
  access_policy_name = "My Access Policy"
  access_levels = {
    my_trusted_proxy = {
      combining_function = "AND"
      conditions = [{
        ip_subnetworks = ["85.85.85.52/32"]
        required_access_levels = null
        members        = []
        negate         = false
        regions        = null
      }]
    }
  }
  access_level_perimeters = {
    enforced = {
      my_trusted_proxy = ["perimeter"]
    }
  }
  perimeters = {
    perimeter = {
      type = "PERIMETER_TYPE_REGULAR"
      dry_run_config = {
        restricted_services     = ["storage.googleapis.com", "bigquery.googleapis.com"]
        vpc_accessible_services = ["storage.googleapis.com", "bigquery.googleapis.com"]
      }
      enforced_config = {
        restricted_services     = ["storage.googleapis.com"]
        vpc_accessible_services = ["storage.googleapis.com"]
      }
    }
  }
  perimeter_projects = {
    perimeter = {
      enforced = [111111111, 222222222]
      dry_run  = [333333333]
    }
  }
}

# tftest:modules=1:resources=2
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| organization_id | Organization id in organizations/nnnnnn format. | <code title="">string</code> | ✓ |  |
| *access_level_perimeters* | Enforced mode -> Access Level -> Perimeters mapping. Enforced mode can be 'enforced' or 'dry_run' | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *access_levels* | Map of Access Levels to be created. For each Access Level you can specify 'ip_subnetworks, required_access_levels, members, negate or regions'. | <code title="map&#40;object&#40;&#123;&#10;combining_function &#61; string&#10;conditions &#61; list&#40;object&#40;&#123;&#10;ip_subnetworks         &#61; list&#40;string&#41;&#10;required_access_levels &#61; list&#40;string&#41;&#10;members                &#61; list&#40;string&#41;&#10;negate                 &#61; string&#10;regions                &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *access_policy_create* | Enable autocreation of the Access Policy | <code title="">bool</code> |  | <code title="">true</code> |
| *access_policy_name* | Referenced Access Policy name | <code title="">string</code> |  | <code title="">null</code> |
| *access_policy_title* | Access Policy title to be created. | <code title="">string</code> |  | <code title="">null</code> |
| *egress_policies* | List of EgressPolicies in the form described in the [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter#egress_policies) | <code title=""></code> |  | <code title="">null</code> |
| *egress_policies_perimeters* | Enforced mode -> Egress Policy -> Perimeters mapping. Enforced mode can be 'enforced' or 'dry_run' | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *ingress_policies* | List of IngressPolicies in the form described in the [documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/access_context_manager_service_perimeter#ingress_policies) | <code title=""></code> |  | <code title="">null</code> |
| *ingress_policies_perimeters* | Enforced mode -> Ingress Policy -> Perimeters mapping. Enforced mode can be 'enforced' or 'dry_run' | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *perimeter_projects* | Perimeter -> Enforced Mode -> Projects Number mapping. Enforced mode can be 'enforced' or 'dry_run'. | <code title="map&#40;map&#40;list&#40;number&#41;&#41;&#41;">map(map(list(number)))</code> |  | <code title="">{}</code> |
| *perimeters* | Set of Perimeters. | <code title="map&#40;object&#40;&#123;&#10;type &#61; string&#10;dry_run_config &#61; object&#40;&#123;&#10;restricted_services     &#61; list&#40;string&#41;&#10;vpc_accessible_services &#61; list&#40;string&#41;&#10;&#125;&#41;&#10;enforced_config &#61; object&#40;&#123;&#10;restricted_services     &#61; list&#40;string&#41;&#10;vpc_accessible_services &#61; list&#40;string&#41;&#10;&#125;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| access_levels | Access Levels. |  |
| access_policy_name | Access Policy resource |  |
| organization_id | Organization id dependent on module resources. |  |
| perimeters_bridge | VPC-SC bridge perimeter resources. |  |
| perimeters_standard | VPC-SC standard perimeter resources. |  |
<!-- END TFDOC -->
