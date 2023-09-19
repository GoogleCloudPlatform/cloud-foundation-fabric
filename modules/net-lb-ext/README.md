# External Passthrough Network Load Balancer Module

This module allows managing a GCE Network Load Balancer and integrates the forwarding rule, regional backend, and optional health check resources. It's designed to be a simple match for the [`compute-vm`](../compute-vm) module, which can be used to manage instance templates and instance groups.

## Examples

- [Referencing existing MIGs](#referencing-existing-migs)
- [Externally manages instances](#externally-managed-instances)
- [End to end example](#end-to-end-example)

### Referencing existing MIGs

This example shows how to reference existing Managed Infrastructure Groups (MIGs).

```hcl
module "instance_template" {
  source          = "./fabric/modules/compute-vm"
  project_id      = var.project_id
  zone            = "europe-west1-b"
  name            = "vm-test"
  create_template = true
  service_account = {
    auto_create = true
  }
  network_interfaces = [
    {
      network    = var.vpc.self_link
      subnetwork = var.subnet.self_link
    }
  ]
  tags = [
    "http-server"
  ]
}

module "mig" {
  source            = "./fabric/modules/compute-mig"
  project_id        = var.project_id
  location          = "europe-west1"
  name              = "mig-test"
  target_size       = 1
  instance_template = module.instance_template.template.self_link
}

module "nlb" {
  source     = "./fabric/modules/net-lb-ext"
  project_id = var.project_id
  region     = "europe-west1"
  name       = "nlb-test"
  backends = [{
    group = module.mig.group_manager.instance_group
  }]
  health_check_config = {
    http = {
      port = 80
    }
  }
}
# tftest modules=3 resources=6
```

### Externally managed instances

This examples shows how to create an NLB by combining externally managed instances (in a custom module or even outside of the current root module) in an unmanaged group. When using internally managed groups, remember to run `terraform apply` each time group instances change.

```hcl
module "nlb" {
  source     = "./fabric/modules/net-lb-ext"
  project_id = var.project_id
  region     = "europe-west1"
  name       = "nlb-test"
  group_configs = {
    my-group = {
      zone = "europe-west1-b"
      instances = [
        "instance-1-self-link",
        "instance-2-self-link"
      ]
    }
  }
  backends = [{
    group = module.nlb.groups.my-group.self_link
  }]
  health_check_config = {
    http = {
      port = 80
    }
  }
}
# tftest modules=1 resources=4
```

### End to end example

This example spins up a simple HTTP server and combines four modules:

- [`nginx`](../cloud-config-container/nginx) from the `cloud-config-container` collection, to manage instance configuration
- [`compute-vm`](../compute-vm) to manage the instance template and unmanaged instance group
- this module to create a Network Load Balancer in front of the managed instance group

Note that the example uses the GCE default service account. You might want to create an ad-hoc service account by combining the [`iam-service-account`](../iam-service-account) module, or by having the GCE VM module create one for you. In both cases, remember to set at least logging write permissions for the service account, or the container on the instances won't be able to start.

```hcl
module "cos-nginx" {
  source = "./fabric/modules/cloud-config-container/nginx"
}

module "instance-group" {
  source     = "./fabric/modules/compute-vm"
  for_each   = toset(["b", "c"])
  project_id = var.project_id
  zone       = "europe-west1-${each.key}"
  name       = "nlb-test-${each.key}"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
  }]
  boot_disk = {
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      type  = "pd-ssd"
      size  = 10
    }
  }
  tags = ["http-server", "ssh"]
  metadata = {
    user-data = module.cos-nginx.cloud_config
  }
  group = { named_ports = {} }
}

module "nlb" {
  source     = "./fabric/modules/net-lb-ext"
  project_id = var.project_id
  region     = "europe-west1"
  name       = "nlb-test"
  ports      = [80]
  backends = [
    for z, mod in module.instance-group : {
      group = mod.group.self_link
    }
  ]
  health_check_config = {
    http = {
      port = 80
    }
  }
}
# tftest modules=3 resources=7
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L189) | Name used for all resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L200) | Project id where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L216) | GCP region. | <code>string</code> | ✓ |  |
| [address](variables.tf#L17) | Optional IP address used for the forwarding rule. | <code>string</code> |  | <code>null</code> |
| [backend_service_config](variables.tf#L23) | Backend service level configuration. | <code title="object&#40;&#123;&#10;  connection_draining_timeout_sec &#61; optional&#40;number&#41;&#10;  connection_tracking &#61; optional&#40;object&#40;&#123;&#10;    idle_timeout_sec          &#61; optional&#40;number&#41;&#10;    persist_conn_on_unhealthy &#61; optional&#40;string&#41;&#10;    track_per_session         &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  failover_config &#61; optional&#40;object&#40;&#123;&#10;    disable_conn_drain        &#61; optional&#40;bool&#41;&#10;    drop_traffic_if_unhealthy &#61; optional&#40;bool&#41;&#10;    ratio                     &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  locality_lb_policy &#61; optional&#40;string&#41;&#10;  log_sample_rate    &#61; optional&#40;number&#41;&#10;  port_name          &#61; optional&#40;string&#41;&#10;  protocol           &#61; optional&#40;string, &#34;UNSPECIFIED&#34;&#41;&#10;  session_affinity   &#61; optional&#40;string&#41;&#10;  timeout_sec        &#61; optional&#40;number&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [backends](variables.tf#L72) | Load balancer backends, balancing mode is one of 'CONNECTION' or 'UTILIZATION'. | <code title="list&#40;object&#40;&#123;&#10;  group       &#61; string&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  failover    &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [description](variables.tf#L83) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [group_configs](variables.tf#L89) | Optional unmanaged groups to create. Can be referenced in backends via outputs. | <code title="map&#40;object&#40;&#123;&#10;  zone        &#61; string&#10;  instances   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  named_ports &#61; optional&#40;map&#40;number&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check](variables.tf#L100) | Name of existing health check to use, disables auto-created health check. | <code>string</code> |  | <code>null</code> |
| [health_check_config](variables.tf#L106) | Optional auto-created health check configuration, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code title="object&#40;&#123;&#10;  check_interval_sec  &#61; optional&#40;number&#41;&#10;  description         &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  enable_logging      &#61; optional&#40;bool, false&#41;&#10;  healthy_threshold   &#61; optional&#40;number&#41;&#10;  timeout_sec         &#61; optional&#40;number&#41;&#10;  unhealthy_threshold &#61; optional&#40;number&#41;&#10;  grpc &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    service_name       &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  http &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  http2 &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  https &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  tcp &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request            &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  ssl &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request            &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  tcp &#61; &#123;&#10;    port_specification &#61; &#34;USE_SERVING_PORT&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [labels](variables.tf#L183) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [ports](variables.tf#L194) | Comma-separated ports, leave null to use all ports. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [protocol](variables.tf#L205) | IP protocol used, defaults to TCP. UDP or L3_DEFAULT can also be used. | <code>string</code> |  | <code>&#34;TCP&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [backend_service](outputs.tf#L17) | Backend resource. |  |
| [backend_service_id](outputs.tf#L22) | Backend id. |  |
| [backend_service_self_link](outputs.tf#L27) | Backend self link. |  |
| [forwarding_rule](outputs.tf#L32) | Forwarding rule resource. |  |
| [forwarding_rule_address](outputs.tf#L37) | Forwarding rule address. |  |
| [forwarding_rule_self_link](outputs.tf#L42) | Forwarding rule self link. |  |
| [group_self_links](outputs.tf#L47) | Optional unmanaged instance group self links. |  |
| [groups](outputs.tf#L54) | Optional unmanaged instance group resources. |  |
| [health_check](outputs.tf#L59) | Auto-created health-check resource. |  |
| [health_check_self_id](outputs.tf#L64) | Auto-created health-check self id. |  |
| [health_check_self_link](outputs.tf#L69) | Auto-created health-check self link. |  |
| [id](outputs.tf#L74) | Fully qualified forwarding rule id. |  |
<!-- END TFDOC -->
