# Minimalistic VPC module

TODO(ludoo): add description.

## Example

```hcl
module "vpc" {
  source     = "../modules/net-vpc"
  project_id = local.projects.host
  name       = "shared"
  iam_roles = {
    default = ["roles/compute.networkUser", "roles/compute.securityAdmin"]
  }
  iam_members = {
    default = {
      "roles/compute.networkUser" = [
        local.service_accounts.service_cloudsvc,
        local.service_accounts.service_gke
      ]
      "roles/compute.securityAdmin" = [
        local.service_accounts.service_gke
      ]
    }
  }
  shared_vpc_host = true
  shared_vpc_service_projects = [
    local.projects.service,
    local.projects.gae
  ]
  subnets = {
    default = {
      ip_cidr_range = var.ip_ranges.shared-default
      region        = var.region
      secondary_ip_range = {
        pods     = var.ip_secondary_ranges.shared-default-pods
        services = var.ip_secondary_ranges.shared-default-services
      }
    }
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | The name of the network being created | <code title="">string</code> | ✓ |  |
| project_id | The ID of the project where this VPC will be created | <code title="">string</code> | ✓ |  |
| *auto_create_subnetworks* | Set to true to create an auto mode subnet, defaults to custom mode. | <code title="">bool</code> |  | <code title="">false</code> |
| *description* | An optional description of this resource (triggers recreation on change). | <code title="">string</code> |  | <code title="">Terraform-managed.</code> |
| *iam_members* | List of IAM members keyed by subnet and role. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *iam_roles* | List of IAM roles keyed by subnet. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *log_config_defaults* | Default configuration for flow logs when enabled. | <code title="object&#40;&#123;&#10;aggregation_interval &#61; string&#10;flow_sampling        &#61; number&#10;metadata             &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;aggregation_interval &#61; &#34;INTERVAL_5_SEC&#34;&#10;flow_sampling        &#61; 0.5&#10;metadata             &#61; &#34;INCLUDE_ALL_METADATA&#34;&#10;&#125;">...</code> |
| *log_configs* | Map of per-subnet optional configurations for flow logs when enabled. | <code title="map&#40;map&#40;string&#41;&#41;">map(map(string))</code> |  | <code title="">{}</code> |
| *peering_config* | VPC peering configuration. | <code title="object&#40;&#123;&#10;peer_vpc_self_link &#61; string&#10;export_routes      &#61; bool&#10;import_routes      &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *routing_mode* | The network routing mode (default 'GLOBAL') | <code title="">string</code> |  | <code title="">GLOBAL</code> |
| *shared_vpc_host* | Makes this project a Shared VPC host if 'true' (default 'false') | <code title="">bool</code> |  | <code title="">false</code> |
| *shared_vpc_service_projects* | Shared VPC service projects to register with this host | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *subnet_descriptions* | Optional map of subnet descriptions, keyed by subnet name. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *subnet_flow_logs* | Optional map of boolean to control flow logs (default is disabled), keyed by subnet name. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *subnet_private_access* | Optional map of boolean to control private Google access (default is enabled), keyed by subnet name. | <code title="map&#40;bool&#41;">map(bool)</code> |  | <code title="">{}</code> |
| *subnets* | The list of subnets being created | <code title="map&#40;object&#40;&#123;&#10;ip_cidr_range      &#61; string&#10;region             &#61; string&#10;secondary_ip_range &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bindings | Subnet IAM bindings. |  |
| name | The name of the VPC being created. |  |
| network | Network resource. |  |
| project_id | Shared VPC host project id. |  |
| self_link | The URI of the VPC being created. |  |
| subnet_ips | Map of subnet address ranges keyed by name. |  |
| subnet_regions | Map of subnet regions keyed by name. |  |
| subnet_secondary_ranges | Map of subnet secondary ranges keyed by name. |  |
| subnet_self_links | Map of subnet self links keyed by name. |  |
| subnets | Subnet resources. |  |
<!-- END TFDOC -->

