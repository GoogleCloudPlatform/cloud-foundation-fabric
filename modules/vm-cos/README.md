# Container Optimized VM module

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| cloud_config_path | None | <code title="">string</code> | ✓ |  |
| name | None | <code title="">string</code> | ✓ |  |
| network | None | <code title="">string</code> | ✓ |  |
| project_id | None | <code title="">string</code> | ✓ |  |
| region | None | <code title="">string</code> | ✓ |  |
| subnetwork | None | <code title="">string</code> | ✓ |  |
| zone | None | <code title="">string</code> | ✓ |  |
| *addresses* | None | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *attached_disks* | Additional disks (only for non-MIG usage). | <code title="">string # pd-standard pd-ssd</code> |  | <code title="">{}</code> |
| *boot_disk* | None | <code title="">"pd-ssd"</code> |  | <code title="{}">{}</code> |
| *cloud_config_vars* | None | <code title="map&#40;any&#41;">map(any)</code> |  | <code title="">{}</code> |
| *docker_log_driver* | None | <code title="">string</code> |  | <code title="">gcplogs</code> |
| *instance_count* | None | <code title="">number</code> |  | <code title="">1</code> |
| *instance_type* | None | <code title="">string</code> |  | <code title="">f1-micro</code> |
| *nat* | None | <code title="object&#40;&#123;&#10;enabled &#61; bool&#10;address &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="{}">{}</code> |
| *options* | None | <code title="object&#40;&#123;&#10;allow_stopping_for_update &#61; bool&#10;automatic_restart         &#61; bool&#10;can_ip_forward            &#61; bool&#10;on_host_maintenance       &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="{}">{}</code> |
| *service_account* | None | <code title="">string</code> |  | <code title=""></code> |
| *stackdriver* | None | <code title="object&#40;&#123;&#10;enable_logging    &#61; bool&#10;enable_monitoring &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="{}">{}</code> |
| *tags* | None | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["ssh"]</code> |
| *use_instance_template* | None | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

<!-- END TFDOC -->
