# Google Cloud NAT Module

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| project_id | Project where resources will be created. | `string` | ✓
| region | Region where resources will be created. | `string` | ✓
| *addresses* | Optional list of external address self links. | `list(string)` | 
| *config_min_ports_per_vm* | Minimum number of ports allocated to a VM from this NAT config. | `number` | 
| *config_source_subnets* | Subnetwork configuration, valid values are ALL_SUBNETWORKS_ALL_IP_RANGES, ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES, LIST_OF_SUBNETWORKS. | `string` | 
| *config_timeouts* | Timeout configurations. | `object({...})` | 
| *create_router* | Create router for Cloud NAT instead of using existing one. | `bool` | 
| *name* | Name of the Cloud NAT resource. | `string` | 
| *network* | Name of the VPC where optional router will be created. | `string` | 
| *prefix* | Optional prefix that will be prepended to resource names. | `string` | 
| *router_asn* | Router ASN used for auto-created router. | `number` | 
| *router_name* | Name of the existing or auto-created router. | `string` | 
| *router_network* | Name of the VPC used for auto-created router. | `string` | 
| *subnetworks* | Subnetworks to NAT, only used when config_source_subnets equals LIST_OF_SUBNETWORKS. | `list(object({...}))` | 

## Outputs

| name | description | sensitive |
|---|---|:---:|
| name | Name of the Cloud NAT. |  |
| nat_ip_allocate_option | NAT IP allocation mode. |  |
| region | Cloud NAT region. |  |
| router | Cloud NAT router resources (if auto created). |  |
| router_name | Cloud NAT router name. |  |
<!-- END TFDOC -->
