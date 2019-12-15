# Minimalistic VPC module

TODO(ludoo): add description.

## Example usage

TODO(ludoo): add example

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| name | The name of the network being created | string | ✓
| project_id | The ID of the project where this VPC will be created | string | ✓
| *auto_create_subnetworks* | Set to true to create an auto mode subnet, defaults to custom mode. | bool | 
| *description* | An optional description of this resource (triggers recreation on change). | string | 
| *iam_members* | List of IAM members keyed by subnet and role. | map(map(list(string))) | 
| *iam_roles* | List of IAM roles keyed by subnet. | map(list(string)) | 
| *log_config_defaults* | Default configuration for flow logs when enabled. | object({...}) | 
| *log_configs* | Map of per-subnet optional configurations for flow logs when enabled. | map(map(string)) | 
| *routing_mode* | The network routing mode (default 'GLOBAL') | string | 
| *shared_vpc_host* | Makes this project a Shared VPC host if 'true' (default 'false') | bool | 
| *shared_vpc_service_projects* | Shared VPC service projects to register with this host | list(string) | 
| *subnet_descriptions* | Optional map of subnet descriptions, keyed by subnet name. | map(string) | 
| *subnet_flow_logs* | Optional map of boolean to control flow logs (default is disabled), keyed by subnet name. | map(bool) | 
| *subnet_private_access* | Optional map of boolean to control private Google access (default is enabled), keyed by subnet name. | map(bool) | 
| *subnets* | The list of subnets being created | map(object({...})) | 

## Outputs

| name | description |
|---|---|
| bindings | Subnet IAM bindings. |
| name | The name of the VPC being created. |
| network | Network resource. |
| project_id | Shared VPC host project id. |
| self_link | The URI of the VPC being created. |
| subnet_ips | Map of subnet address ranges keyed by name. |
| subnet_regions | Map of subnet regions keyed by name. |
| subnet_secondary_ranges | Map of subnet secondary ranges keyed by name. |
| subnet_self_links | Map of subnet self links keyed by name. |
| subnets | Subnet resources. |
<!-- END TFDOC -->

