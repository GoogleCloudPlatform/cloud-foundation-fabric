# Internal Load Balancer Module

This module allows managing a GCE Internal Load Balancer and integrates the forwarding rule, regional backend, and optional health check resources. It's designed to be a simple match for the [`compute-vm`](../compute-vm) module, which can be used to manage instance templates and instance groups.

## Issues

TODO(ludoo): check if this is still the case after splitting out MIG from compute-vm

There are some corner cases (eg when switching the instance template from internal service account to an externally managed one) where Terraform raises a cycle error on apply. In these situations, run successive applies targeting resources used in the template first then the template itself, and the cycle should be fixed.

One other issue is a `Provider produced inconsistent final plan` error which is sometimes raised when switching template version. This seems to be related to this [open provider issue](https://github.com/terraform-providers/terraform-provider-google/issues/3937), but it's relatively harmless since the resource is updated, and subsequent applies raise no errors.

## Examples

### Externally managed instances

This examples shows how to create an ILB by combining externally managed instances (in a custom module or even outside of the current root module) in an unmanaged group. When using internally managed groups, remember to run `terraform apply` each time group instances change.

```hcl
module "ilb" {
  source        = "./modules/net-ilb"
  project_id    = var.project_id
  region        = "europe-west1"
  name          = "ilb-test"
  service_label = "ilb-test"
  network       = var.vpc.self_link
  subnetwork    = var.subnet.self_link
  group_configs = {
    my-group = {
      zone = "europe-west1-b", named_ports = null
      instances = [
        "instance-1-self-link",
        "instance-2-self-link"
      ]
    }
  }
  backends = [{
    failover       = false
    group          = module.ilb.groups.my-group.self_link
    balancing_mode = "CONNECTION"
  }]
  health_check_config = {
    type = "http", check = { port = 80 }, config = {}, logging = true
  }
}
# tftest modules=1 resources=4
```

### End to end example

This example spins up a simple HTTP server and combines four modules:

- [`nginx`](../cloud-config-container/nginx) from the `cloud-config-container` collection, to manage instance configuration
- [`compute-vm`](../compute-vm) to manage the instance template and unmanaged instance group
- this module to create an Internal Load Balancer in front of the managed instance group

Note that the example uses the GCE default service account. You might want to create an ad-hoc service account by combining the [`iam-service-account`](../iam-service-account) module, or by having the GCE VM module create one for you. In both cases, remember to set at least logging write permissions for the service account, or the container on the instances won't be able to start.

```hcl
module "cos-nginx" {
  source = "./modules/cloud-config-container/nginx"
}

module "instance-group" {
  source     = "./modules/compute-vm"
  for_each = toset(["b", "c"])
  project_id = var.project_id
  zone     = "europe-west1-${each.key}"
  name       = "ilb-test-${each.key}"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
  }]
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  tags = ["http-server", "ssh"]
  metadata = {
    user-data = module.cos-nginx.cloud_config
  }
  group = { named_ports = {} }
}

module "ilb" {
  source        = "./modules/net-ilb"
  project_id    = var.project_id
  region        = "europe-west1"
  name          = "ilb-test"
  service_label = "ilb-test"
  network       = var.vpc.self_link
  subnetwork    = var.subnet.self_link
  ports         = [80]
  backends = [
    for z, mod in module.instance-group : {
      failover       = false
      group          = mod.group.self_link
      balancing_mode = "CONNECTION"
    }
  ]
  health_check_config = {
    type = "http", check = { port = 80 }, config = {}, logging = true
  }
}
# tftest modules=3 resources=7
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [backends](variables.tf#L33) | Load balancer backends, balancing mode is one of 'CONNECTION' or 'UTILIZATION'. | <code title="list&#40;object&#40;&#123;&#10;  failover       &#61; bool&#10;  group          &#61; string&#10;  balancing_mode &#61; string&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [name](variables.tf#L98) | Name used for all resources. | <code>string</code> | ✓ |  |
| [network](variables.tf#L103) | Network used for resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L114) | Project id where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L125) | GCP region. | <code>string</code> | ✓ |  |
| [subnetwork](variables.tf#L136) | Subnetwork used for the forwarding rule. | <code>string</code> | ✓ |  |
| [address](variables.tf#L17) | Optional IP address used for the forwarding rule. | <code>string</code> |  | <code>null</code> |
| [backend_config](variables.tf#L23) | Optional backend configuration. | <code title="object&#40;&#123;&#10;  session_affinity                &#61; string&#10;  timeout_sec                     &#61; number&#10;  connection_draining_timeout_sec &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [failover_config](variables.tf#L42) | Optional failover configuration. | <code title="object&#40;&#123;&#10;  disable_connection_drain  &#61; bool&#10;  drop_traffic_if_unhealthy &#61; bool&#10;  ratio                     &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [global_access](variables.tf#L52) | Global access, defaults to false if not set. | <code>bool</code> |  | <code>null</code> |
| [group_configs](variables.tf#L58) | Optional unmanaged groups to create. Can be referenced in backends via outputs. | <code title="map&#40;object&#40;&#123;&#10;  instances   &#61; list&#40;string&#41;&#10;  named_ports &#61; map&#40;number&#41;&#10;  zone        &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check](variables.tf#L68) | Name of existing health check to use, disables auto-created health check. | <code>string</code> |  | <code>null</code> |
| [health_check_config](variables.tf#L74) | Configuration of the auto-created helth check. | <code title="object&#40;&#123;&#10;  type    &#61; string      &#35; http https tcp ssl http2&#10;  check   &#61; map&#40;any&#41;    &#35; actual health check block attributes&#10;  config  &#61; map&#40;number&#41; &#35; interval, thresholds, timeout&#10;  logging &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  type &#61; &#34;http&#34;&#10;  check &#61; &#123;&#10;    port_specification &#61; &#34;USE_SERVING_PORT&#34;&#10;  &#125;&#10;  config  &#61; &#123;&#125;&#10;  logging &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |
| [labels](variables.tf#L92) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [ports](variables.tf#L108) | Comma-separated ports, leave null to use all ports. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [protocol](variables.tf#L119) | IP protocol used, defaults to TCP. | <code>string</code> |  | <code>&#34;TCP&#34;</code> |
| [service_label](variables.tf#L130) | Optional prefix of the fully qualified forwarding rule name. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [backend](outputs.tf#L17) | Backend resource. |  |
| [backend_id](outputs.tf#L22) | Backend id. |  |
| [backend_self_link](outputs.tf#L27) | Backend self link. |  |
| [forwarding_rule](outputs.tf#L32) | Forwarding rule resource. |  |
| [forwarding_rule_address](outputs.tf#L37) | Forwarding rule address. |  |
| [forwarding_rule_id](outputs.tf#L42) | Forwarding rule id. |  |
| [forwarding_rule_self_link](outputs.tf#L47) | Forwarding rule self link. |  |
| [group_self_links](outputs.tf#L52) | Optional unmanaged instance group self links. |  |
| [groups](outputs.tf#L59) | Optional unmanaged instance group resources. |  |
| [health_check](outputs.tf#L64) | Auto-created health-check resource. |  |
| [health_check_self_id](outputs.tf#L69) | Auto-created health-check self id. |  |
| [health_check_self_link](outputs.tf#L74) | Auto-created health-check self link. |  |

<!-- END TFDOC -->
