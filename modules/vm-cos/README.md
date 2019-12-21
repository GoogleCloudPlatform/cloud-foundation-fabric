# Container Optimized VM module

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| cloud_config_path | Path to cloud config template file to set in metadata. | <code title="">string</code> | ✓ |  |
| name | Instance name. | <code title="">string</code> | ✓ |  |
| network | Network name (self link for shared vpc). | <code title="">string</code> | ✓ |  |
| project_id | Project id. | <code title="">string</code> | ✓ |  |
| region | Compute region. | <code title="">string</code> | ✓ |  |
| subnetwork | Subnetwork name (self link for shared vpc). | <code title="">string</code> | ✓ |  |
| zone | Compute zone. | <code title="">string</code> | ✓ |  |
| *addresses* | Optional internal addresses (only for non-MIG usage). | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *attached_disks* | Additional disks (only for non-MIG usage). | <code title="map&#40;object&#40;&#123;&#10;string&#10;size &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *boot_disk* | Boot disk properties. | <code title="object&#40;&#123;&#10;image &#61; string&#10;size  &#61; number&#10;string&#10;&#125;&#41;">object({...})</code> |  | <code title="{}">{}</code> |
| *cloud_config_vars* | Custom variables passed to cloud config template. | <code title="map&#40;any&#41;">map(any)</code> |  | <code title="">{}</code> |
| *instance_count* | Number of instances to create (only for non-MIG usage). | <code title="">number</code> |  | <code title="">1</code> |
| *instance_type* | Instance type. | <code title="">string</code> |  | <code title="">f1-micro</code> |
| *nat* | External address properties (addresses only for non-MIG usage). | <code title="object&#40;&#123;&#10;enabled   &#61; bool&#10;addresses &#61; list&#40;string&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="{}">{}</code> |
| *options* | Instance options. | <code title="object&#40;&#123;&#10;allow_stopping_for_update &#61; bool&#10;automatic_restart         &#61; bool&#10;can_ip_forward            &#61; bool&#10;on_host_maintenance       &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="{}">{}</code> |
| *service_account* | Service account email (leave empty to auto-create). | <code title="">string</code> |  | <code title=""></code> |
| *stackdriver* | Stackdriver options set in metadata. | <code title="object&#40;&#123;&#10;enable_logging    &#61; bool&#10;enable_monitoring &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="{}">{}</code> |
| *tags* | Instance tags. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["ssh"]</code> |
| *use_instance_template* | Create instance template instead of instances. | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

<!-- END TFDOC -->
