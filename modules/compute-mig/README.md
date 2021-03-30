# GCE Managed Instance Group module

This module allows creating a managed instance group supporting one or more application versions via instance templates. A health check and an autoscaler can also be optionally created.

This module can be coupled with the [`compute-vm`](../compute-vm) module which can manage instance templates, and the [`net-ilb`](../net-ilb) module to assign the MIG to a backend wired to an Internal Load Balancer. The first use case is shown in the examples below.

## Examples

This example shows how to manage a simple MIG that leverages the `compute-vm` module to manage the underlying instance template. The following sub-examples will only show how to enable specific features of this module, and won't replicate the combined setup.

```hcl
module "cos-nginx" {
  source = "./modules/cloud-config-container/nginx"
}

module "nginx-template" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  name       = "nginx-template"
  region     = "europe-west1"
  zones      = ["europe-west1-b", "europe-west1-d"]
  tags       = ["http-server", "ssh"]
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
  use_instance_template = true
  metadata = {
    user-data = module.cos-nginx.cloud_config
  }
}

module "nginx-mig" {
  source      = "./modules/compute-mig"
  project_id  = "my-project"
  location    = "europe-west1-b"
  name        = "mig-test"
  target_size = 2
  default_version = {
    instance_template = module.nginx-template.template.self_link
    name              = "default"
  }
}
# tftest:modules=2:resources=2
```

### Multiple versions

If multiple versions are desired, use more `compute-vm` instances for the additional templates used in each version (not shown here), and reference them like this:

```hcl
module "cos-nginx" {
  source = "./modules/cloud-config-container/nginx"
}

module "nginx-template" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  name       = "nginx-template"
  region     = "europe-west1"
  zones      = ["europe-west1-b", "europe-west1-d"]
  tags       = ["http-server", "ssh"]
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
  use_instance_template  = true
  metadata = {
    user-data = module.cos-nginx.cloud_config
  }
}

module "nginx-mig" {
  source      = "./modules/compute-mig"
  project_id  = "my-project"
  location    = "europe-west1-b"
  name        = "mig-test"
  target_size = 3
  default_version = {
    instance_template = module.nginx-template.template.self_link
    name = "default"
  }
  versions = {
    canary = {
      instance_template = module.nginx-template.template.self_link
      target_type = "fixed"
      target_size = 1
    }
  }
}
# tftest:modules=2:resources=2
```

### Health check and autohealing policies

Autohealing policies can use an externally defined health check, or have this module auto-create one:

```hcl
module "cos-nginx" {
  source = "./modules/cloud-config-container/nginx"
}

module "nginx-template" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  name       = "nginx-template"
  region     = "europe-west1"
  zones      = ["europe-west1-b", "europe-west1-d"]
  tags       = ["http-server", "ssh"]
  network_interfaces = [{
    network    = var.vpc.self_link,
    subnetwork = var.subnet.self_link,
    nat        = false,
    addresses  = null
    alias_ips  = null
  }]
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  use_instance_template  = true
  metadata = {
    user-data = module.cos-nginx.cloud_config
  }
}

module "nginx-mig" {
  source = "./modules/compute-mig"
  project_id = "my-project"
  location     = "europe-west1-b"
  name       = "mig-test"
  target_size   = 3
  default_version = {
    instance_template = module.nginx-template.template.self_link
    name = "default"
  }
  auto_healing_policies = {
    health_check      = module.nginx-mig.health_check.self_link
    initial_delay_sec = 30
  }
  health_check_config = {
    type    = "http"
    check   = { port = 80 }
    config  = {}
    logging = true
  }
}
# tftest:modules=2:resources=3
```

### Autoscaling

The module can create and manage an autoscaler associated with the MIG. When using autoscaling do not set the `target_size` variable or set it to `null`. Here we show a CPU utilization autoscaler, the other available modes are load balancing utilization and custom metric, like the underlying autoscaler resource.

```hcl
module "cos-nginx" {
  source = "./modules/cloud-config-container/nginx"
}

module "nginx-template" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  name       = "nginx-template"
  region     = "europe-west1"
  zones      = ["europe-west1-b", "europe-west1-d"]
  tags       = ["http-server", "ssh"]
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
  use_instance_template  = true
  metadata = {
    user-data = module.cos-nginx.cloud_config
  }
}

module "nginx-mig" {
  source = "./modules/compute-mig"
  project_id = "my-project"
  location     = "europe-west1-b"
  name       = "mig-test"
  target_size   = 3
  default_version = {
    instance_template = module.nginx-template.template.self_link
    name = "default"
  }
  autoscaler_config = {
    max_replicas                      = 3
    min_replicas                      = 1
    cooldown_period                   = 30
    cpu_utilization_target            = 0.65
    load_balancing_utilization_target = null
    metric                            = null
  }
}
# tftest:modules=2:resources=3
```

### Update policy

```hcl
module "cos-nginx" {
  source = "./modules/cloud-config-container/nginx"
}

module "nginx-template" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  name       = "nginx-template"
  region     = "europe-west1"
  zones      = ["europe-west1-b", "europe-west1-d"]
  tags       = ["http-server", "ssh"]
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
  use_instance_template  = true
  metadata = {
    user-data = module.cos-nginx.cloud_config
  }
}

module "nginx-mig" {
  source = "./modules/compute-mig"
  project_id = "my-project"
  location     = "europe-west1-b"
  name       = "mig-test"
  target_size   = 3
  default_version = {
    instance_template = module.nginx-template.template.self_link
    name = "default"
  }
  update_policy = {
    type                 = "PROACTIVE"
    minimal_action       = "REPLACE"
    min_ready_sec        = 30
    max_surge_type       = "fixed"
    max_surge            = 1
    max_unavailable_type = null
    max_unavailable      = null
  }
}
# tftest:modules=2:resources=2
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| default_version | Default application version template. Additional versions can be specified via the `versions` variable. | <code title="object&#40;&#123;&#10;instance_template &#61; string&#10;name              &#61; string&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| location | Compute zone, or region if `regional` is set to true. | <code title="">string</code> | ✓ |  |
| name | Managed group name. | <code title="">string</code> | ✓ |  |
| project_id | Project id. | <code title="">string</code> | ✓ |  |
| *auto_healing_policies* | Auto-healing policies for this group. | <code title="object&#40;&#123;&#10;health_check      &#61; string&#10;initial_delay_sec &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *autoscaler_config* | Optional autoscaler configuration. Only one of 'cpu_utilization_target' 'load_balancing_utilization_target' or 'metric' can be not null. | <code title="object&#40;&#123;&#10;max_replicas                      &#61; number&#10;min_replicas                      &#61; number&#10;cooldown_period                   &#61; number&#10;cpu_utilization_target            &#61; number&#10;load_balancing_utilization_target &#61; number&#10;metric &#61; object&#40;&#123;&#10;name                       &#61; string&#10;single_instance_assignment &#61; number&#10;target                     &#61; number&#10;type &#61; string &#35; GAUGE, DELTA_PER_SECOND, DELTA_PER_MINUTE&#10;filter                     &#61; string&#10;&#125;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *health_check_config* | Optional auto-created health check configuration, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code title="object&#40;&#123;&#10;type &#61; string      &#35; http https tcp ssl http2&#10;check   &#61; map&#40;any&#41;    &#35; actual health check block attributes&#10;config  &#61; map&#40;number&#41; &#35; interval, thresholds, timeout&#10;logging &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *named_ports* | Named ports. | <code title="map&#40;number&#41;">map(number)</code> |  | <code title="">null</code> |
| *regional* | Use regional instance group. When set, `location` should be set to the region. | <code title="">bool</code> |  | <code title="">false</code> |
| *target_pools* | Optional list of URLs for target pools to which new instances in the group are added. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *target_size* | Group target size, leave null when using an autoscaler. | <code title="">number</code> |  | <code title="">null</code> |
| *update_policy* | Update policy. Type can be 'OPPORTUNISTIC' or 'PROACTIVE', action 'REPLACE' or 'restart', surge type 'fixed' or 'percent'. | <code title="object&#40;&#123;&#10;type &#61; string &#35; OPPORTUNISTIC &#124; PROACTIVE&#10;minimal_action       &#61; string &#35; REPLACE &#124; RESTART&#10;min_ready_sec        &#61; number&#10;max_surge_type       &#61; string &#35; fixed &#124; percent&#10;max_surge            &#61; number&#10;max_unavailable_type &#61; string&#10;max_unavailable      &#61; number&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *versions* | Additional application versions, target_type is either 'fixed' or 'percent'. | <code title="map&#40;object&#40;&#123;&#10;instance_template &#61; string&#10;target_type       &#61; string &#35; fixed &#124; percent&#10;target_size       &#61; number&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">null</code> |
| *wait_for_instances* | Wait for all instances to be created/updated before returning. | <code title="">bool</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| autoscaler | Auto-created autoscaler resource. |  |
| group_manager | Instance group resource. |  |
| health_check | Auto-created health-check resource. |  |
<!-- END TFDOC -->

## TODO

- [ ] add support for instance groups
