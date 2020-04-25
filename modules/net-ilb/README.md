# Internal Load Balancer Module

This module allows managing a GCE Internal Load Balancer and integrates the forwarding rule, regional backend, and optional health check resources.

## Example

```hcl
module "org" {
  source      = "./modules/organization"
  org_id      = 1234567890
  iam_roles   = ["roles/projectCreator"]
  iam_members = { "roles/projectCreator" = ["group:cloud-admins@example.org"] }
  policy_boolean = {
    "constraints/compute.disableGuestAttributesAccess" = true
    "constraints/compute.skipDefaultNetworkCreation" = true
  }
  policy_list = {
    "constraints/compute.trustedImageProjects" = {
      inherit_from_parent = null
      suggested_value = null
      status = true
      values = ["projects/my-project"]
    }
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| backends | Load balancer backends, balancing mode is one of 'CONNECTION' or 'UTILIZATION'. | <code title="list&#40;object&#40;&#123;&#10;failover       &#61; bool&#10;group          &#61; string&#10;balancing_mode &#61; string&#10;&#125;&#41;&#41;">list(object({...}))</code> | ✓ |  |
| name | Name used for all resources. | <code title="">string</code> | ✓ |  |
| network | Network used for resources. | <code title="">string</code> | ✓ |  |
| project_id | Project id where resources will be created. | <code title="">string</code> | ✓ |  |
| region | GCP region. | <code title="">string</code> | ✓ |  |
| subnetwork | Subnetwork used for the forwarding rule. | <code title="">string</code> | ✓ |  |
| *address* | Optional IP address used for the forwarding rule. | <code title="">string</code> |  | <code title="">null</code> |
| *backend_config* | Optional backend configuration. | <code title="object&#40;&#123;&#10;session_affinity                &#61; string&#10;timeout_sec                     &#61; number&#10;connection_draining_timeout_sec &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *failover_config* | Optional failover configuration. | <code title="object&#40;&#123;&#10;disable_connection_drain  &#61; bool&#10;drop_traffic_if_unhealthy &#61; bool&#10;ratio                     &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *global_access* | Global access, defaults to false if not set. | <code title="">bool</code> |  | <code title="">null</code> |
| *health_check* | Name of existing health check to use, disables auto-created health check. | <code title="">string</code> |  | <code title="">null</code> |
| *health_check_config* | Configuration of the auto-created helth check. | <code title="object&#40;&#123;&#10;type &#61; string      &#35; http https tcp ssl http2&#10;check  &#61; map&#40;any&#41;    &#35; actual health check block attributes&#10;config &#61; map&#40;number&#41; &#35; interval, thresholds, timeout&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;type &#61; &#34;http&#34;&#10;check &#61; &#123;&#10;port_specification &#61; &#34;USE_SERVING_PORT&#34;&#10;&#125;&#10;config &#61; &#123;&#125;&#10;&#125;">...</code> |
| *labels* | Labels set on resources. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *log_sample_rate* | Set a value between 0 and 1 to enable logging for resources, and set the sampling rate for backend logging. | <code title="">number</code> |  | <code title="">null</code> |
| *ports* | Comma-separated ports, leave null to use all ports. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">null</code> |
| *protocol* | IP protocol used, defaults to TCP. | <code title="">string</code> |  | <code title="">TCP</code> |
| *service_label* | Optional prefix of the fully qualified forwarding rule name. | <code title="">string</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| backend | Backend resource. |  |
| backend_id | Backend id. |  |
| backend_self_link | Backend self link. |  |
| forwarding_rule | Forwarding rule resource. |  |
| forwarding_rule_address | Forwarding rule address. |  |
| forwarding_rule_id | Forwarding rule id. |  |
| forwarding_rule_self_link | Forwarding rule self link. |  |
| health_check | Auto-created health-check resource. |  |
| health_check_self_id | Auto-created health-check self id. |  |
| health_check_self_link | Auto-created health-check self link. |  |
<!-- END TFDOC -->
