# Minimalistic VPC module

TODO(ludoo): add description.

## Example usage

TODO(ludoo): add example

## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| name | The name of the network being created | string | ✓
| project_id | The ID of the project where this VPC will be created | string | ✓
| *auto_create_subnetworks* | When set to true, the network is created in 'auto subnet mode' and it will create a subnet for each region automatically across the 10.128.0.0/9 address range. When set to false, the network is created in 'custom subnet mode' so the user can explicitly connect subnetwork resources. | bool | 
| *description* | An optional description of this resource. The resource must be recreated to modify this field. | string | 
| *iam_members* | List of IAM members keyed by subnet and role. | map | 
| *iam_roles* | List of IAM roles keyed by subnet. | map | 
| *log_config_defaults* | Default configuration for flow logs when enabled. | object | 
| *log_configs* | Map of per-subnet optional configurations for flow logs when enabled. | map | 
| *routing_mode* | The network routing mode (default 'GLOBAL') | string | 
| *shared_vpc_host* | Makes this project a Shared VPC host if 'true' (default 'false') | bool | 
| *shared_vpc_service_projects* | Shared VPC service projects to register with this host | list | 
| *subnet_descriptions* | Optional map of subnet descriptions, keyed by subnet name. | map | 
| *subnet_flow_logs* | Optional map of boolean to control flow logs (default is disabled), keyed by subnet name. | map | 
| *subnet_private_access* | Optional map of boolean to control private Google access (default is enabled), keyed by subnet name. | map | 
| *subnets* | The list of subnets being created | object map | 

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

