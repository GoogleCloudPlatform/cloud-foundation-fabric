# Internal Load Balancer Module

This module allows managing a GCE Internal Load Balancer and integrates the forwarding rule, regional backend, and optional health check resources. It's designed to be a simple match for the [`compute-vm`](../compute-vm) module, which can be used to manage instance templates and instance groups.

## TODO

- [ ] add a variable for setting address purpose to `SHARED_LOADBALANCER_VIP` and an output for the address once the [provider support has been implemented](https://github.com/terraform-providers/terraform-provider-google/issues/6499)

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
# tftest:modules=1:resources=4
```

### End to end example

This example spins up a simple HTTP server and combines four modules:

- [`nginx`](../cloud-config-container/nginx) from the `cloud-config-container` collection, to manage instance configuration
- [`compute-vm`](../compute-vm) to manage the instance template and unmanaged instance group
- this module to create an Internal Load Balancer in front of the managed instance group

Note that the example uses the GCE default service account. You might want to create an ad-hoc service account by combining the [`iam-service-accounts`](../iam-service-accounts) module, or by having the GCE VM module create one for you. In both cases, remember to set at least logging write permissions for the service account, or the container on the instances won't be able to start.

```hcl
module "cos-nginx" {
  source = "./modules/cloud-config-container/nginx"
}

module "instance-group" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  region     = "europe-west1"
  zones      = ["europe-west1-b", "europe-west1-c"]
  name       = "ilb-test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
    alias_ips  = null
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
    for name, group in module.instance-group.groups : {
      failover       = false
      group          = group.self_link
      balancing_mode = "CONNECTION"
    }
  ]
  health_check_config = {
    type = "http", check = { port = 80 }, config = {}, logging = true
  }
}
# tftest:modules=2:resources=6
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
| *group_configs* | Optional unmanaged groups to create. Can be referenced in backends via outputs. | <code title="map&#40;object&#40;&#123;&#10;instances   &#61; list&#40;string&#41;&#10;named_ports &#61; map&#40;number&#41;&#10;zone        &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *health_check* | Name of existing health check to use, disables auto-created health check. | <code title="">string</code> |  | <code title="">null</code> |
| *health_check_config* | Configuration of the auto-created helth check. | <code title="object&#40;&#123;&#10;type &#61; string      &#35; http https tcp ssl http2&#10;check   &#61; map&#40;any&#41;    &#35; actual health check block attributes&#10;config  &#61; map&#40;number&#41; &#35; interval, thresholds, timeout&#10;logging &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;type &#61; &#34;http&#34;&#10;check &#61; &#123;&#10;port_specification &#61; &#34;USE_SERVING_PORT&#34;&#10;&#125;&#10;config  &#61; &#123;&#125;&#10;logging &#61; false&#10;&#125;">...</code> |
| *labels* | Labels set on resources. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
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
| group_self_links | Optional unmanaged instance group self links. |  |
| groups | Optional unmanaged instance group resources. |  |
| health_check | Auto-created health-check resource. |  |
| health_check_self_id | Auto-created health-check self id. |  |
| health_check_self_link | Auto-created health-check self link. |  |
<!-- END TFDOC -->
