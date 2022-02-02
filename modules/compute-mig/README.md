# GCE Managed Instance Group module

This module allows creating a managed instance group supporting one or more application versions via instance templates. Optionally, a health check and an autoscaler can be created, and the managed instance group can be configured to be stateful.

This module can be coupled with the [`compute-vm`](../compute-vm) module which can manage instance templates, and the [`net-ilb`](../net-ilb) module to assign the MIG to a backend wired to an Internal Load Balancer. The first use case is shown in the examples below. 

Stateful disks can be created directly, as shown in the last example below.

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
  zone     = "europe-west1-b"
  tags       = ["http-server", "ssh"]
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
  create_template = true
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
# tftest modules=2 resources=2
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
  zone     = "europe-west1-b"
  tags       = ["http-server", "ssh"]
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
  create_template  = true
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
# tftest modules=2 resources=2
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
  zone     = "europe-west1-b"
  tags       = ["http-server", "ssh"]
  network_interfaces = [{
    network    = var.vpc.self_link,
    subnetwork = var.subnet.self_link,
    nat        = false,
    addresses  = null
  }]
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  create_template  = true
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
# tftest modules=2 resources=3
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
  zone     = "europe-west1-b"
  tags       = ["http-server", "ssh"]
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
  create_template  = true
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
# tftest modules=2 resources=3
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
  zone     = "europe-west1-b"
  tags       = ["http-server", "ssh"]
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
  create_template  = true
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
# tftest modules=2 resources=2
```

### Stateful MIGs - MIG Config

Stateful MIGs have some limitations documented [here](https://cloud.google.com/compute/docs/instance-groups/configuring-stateful-migs#limitations). Enforcement of these requirements is the responsibility of users of this module. 

You can configure a disk defined in the instance template to be stateful  for all instances in the MIG by configuring in the MIG's stateful policy, using the `stateful_disk_mig` variable. Alternatively, you can also configure stateful persistent disks individually per instance of the MIG by setting the `stateful_disk_instance` variable. A discussion on these scenarios can be found in the [docs](https://cloud.google.com/compute/docs/instance-groups/configuring-stateful-disks-in-migs).

An example using only the configuration at the MIG level can be seen below.

Note that when referencing the stateful disk, you use `device_name` and not `disk_name`.


```hcl
module "cos-nginx" {
  source = "./modules/cloud-config-container/nginx"
}

module "nginx-template" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  name       = "nginx-template"
  zone     = "europe-west1-b"
  tags       = ["http-server", "ssh"]
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
  attached_disks = [{
    name        = "repd-1"
    size        = null
    source_type = "attach"
    source      = "regions/${var.region}/disks/repd-test-1"
    options = {
      mode         = "READ_ONLY"
      replica_zone = "${var.region}-c"
      type         = "PERSISTENT"
    }
  }]
  create_template  = true
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
  stateful_config = {
    per_instance_config = {},
    mig_config = {
      stateful_disks = {
        persistent-disk-1 = {
          delete_rule = "NEVER"
        }
      }
    }
  }
}
# tftest modules=2 resources=3

```

### Stateful MIGs - Instance Config
Here is an example defining the stateful config at the instance level. 

Note that you will need to know the instance name in order to use this configuration.

```hcl
module "cos-nginx" {
  source = "./modules/cloud-config-container/nginx"
}

module "nginx-template" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  name       = "nginx-template"
  zone     = "europe-west1-b"
  tags       = ["http-server", "ssh"]
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
  attached_disks = [{
    name        = "repd-1"
    size        = null
    source_type = "attach"
    source      = "regions/${var.region}/disks/repd-test-1"
    options = {
      mode         = "READ_ONLY"
      replica_zone = "${var.region}-c"
      type         = "PERSISTENT"
    }
  }]
  create_template  = true
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
  stateful_config = {
    per_instance_config = {
      # note that this needs to be the name of an existing instance within the Managed Instance Group
      instance-1 = {
        stateful_disks = {
          persistent-disk-1 = {
            source = "test-disk", 
            mode = "READ_ONLY",
            delete_rule= "NEVER",
          },
        },
        metadata = {
          foo = "bar"
        },
        update_config = {
          minimal_action                   = "NONE",
          most_disruptive_allowed_action   = "REPLACE",
          remove_instance_state_on_destroy = false, 
        },
      },
    },
    mig_config = {
      stateful_disks = {
      }
    }
  }
}
# tftest modules=2 resources=4

```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [default_version](variables.tf#L45) | Default application version template. Additional versions can be specified via the `versions` variable. | <code title="object&#40;&#123;&#10;  instance_template &#61; string&#10;  name              &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [location](variables.tf#L64) | Compute zone, or region if `regional` is set to true. | <code>string</code> | ✓ |  |
| [name](variables.tf#L68) | Managed group name. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L79) | Project id. | <code>string</code> | ✓ |  |
| [auto_healing_policies](variables.tf#L17) | Auto-healing policies for this group. | <code title="object&#40;&#123;&#10;  health_check      &#61; string&#10;  initial_delay_sec &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [autoscaler_config](variables.tf#L26) | Optional autoscaler configuration. Only one of 'cpu_utilization_target' 'load_balancing_utilization_target' or 'metric' can be not null. | <code title="object&#40;&#123;&#10;  max_replicas                      &#61; number&#10;  min_replicas                      &#61; number&#10;  cooldown_period                   &#61; number&#10;  cpu_utilization_target            &#61; number&#10;  load_balancing_utilization_target &#61; number&#10;  metric &#61; object&#40;&#123;&#10;    name                       &#61; string&#10;    single_instance_assignment &#61; number&#10;    target                     &#61; number&#10;    type                       &#61; string &#35; GAUGE, DELTA_PER_SECOND, DELTA_PER_MINUTE&#10;    filter                     &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [health_check_config](variables.tf#L53) | Optional auto-created health check configuration, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code title="object&#40;&#123;&#10;  type    &#61; string      &#35; http https tcp ssl http2&#10;  check   &#61; map&#40;any&#41;    &#35; actual health check block attributes&#10;  config  &#61; map&#40;number&#41; &#35; interval, thresholds, timeout&#10;  logging &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [named_ports](variables.tf#L73) | Named ports. | <code>map&#40;number&#41;</code> |  | <code>null</code> |
| [regional](variables.tf#L84) | Use regional instance group. When set, `location` should be set to the region. | <code>bool</code> |  | <code>false</code> |
| [stateful_config](variables.tf#L90) | Stateful configuration can be done by individual instances or for all instances in the MIG. They key in per_instance_config is the name of the specific instance. The key of the stateful_disks is the 'device_name' field of the resource. Please note that device_name is defined at the OS mount level, unlike the disk name. | <code title="object&#40;&#123;&#10;  per_instance_config &#61; map&#40;object&#40;&#123;&#10;    stateful_disks &#61; map&#40;object&#40;&#123;&#10;      source      &#61; string&#10;      mode        &#61; string &#35; READ_WRITE &#124; READ_ONLY &#10;      delete_rule &#61; string &#35; NEVER &#124; ON_PERMANENT_INSTANCE_DELETION&#10;    &#125;&#41;&#41;&#10;    metadata &#61; map&#40;string&#41;&#10;    update_config &#61; object&#40;&#123;&#10;      minimal_action                   &#61; string &#35; NONE &#124; REPLACE &#124; RESTART &#124; REFRESH&#10;      most_disruptive_allowed_action   &#61; string &#35; REPLACE &#124; RESTART &#124; REFRESH &#124; NONE&#10;      remove_instance_state_on_destroy &#61; bool&#10;    &#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#10;&#10;  mig_config &#61; object&#40;&#123;&#10;    stateful_disks &#61; map&#40;object&#40;&#123;&#10;      delete_rule &#61; string &#35; NEVER &#124; ON_PERMANENT_INSTANCE_DELETION&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#10;&#10;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [target_pools](variables.tf#L121) | Optional list of URLs for target pools to which new instances in the group are added. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [target_size](variables.tf#L127) | Group target size, leave null when using an autoscaler. | <code>number</code> |  | <code>null</code> |
| [update_policy](variables.tf#L133) | Update policy. Type can be 'OPPORTUNISTIC' or 'PROACTIVE', action 'REPLACE' or 'restart', surge type 'fixed' or 'percent'. | <code title="object&#40;&#123;&#10;  type                 &#61; string &#35; OPPORTUNISTIC &#124; PROACTIVE&#10;  minimal_action       &#61; string &#35; REPLACE &#124; RESTART&#10;  min_ready_sec        &#61; number&#10;  max_surge_type       &#61; string &#35; fixed &#124; percent&#10;  max_surge            &#61; number&#10;  max_unavailable_type &#61; string&#10;  max_unavailable      &#61; number&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [versions](variables.tf#L147) | Additional application versions, target_type is either 'fixed' or 'percent'. | <code title="map&#40;object&#40;&#123;&#10;  instance_template &#61; string&#10;  target_type       &#61; string &#35; fixed &#124; percent&#10;  target_size       &#61; number&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [wait_for_instances](variables.tf#L157) | Wait for all instances to be created/updated before returning. | <code>bool</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [autoscaler](outputs.tf#L17) | Auto-created autoscaler resource. |  |
| [group_manager](outputs.tf#L26) | Instance group resource. |  |
| [health_check](outputs.tf#L35) | Auto-created health-check resource. |  |

<!-- END TFDOC -->
## TODO

- [✓] add support for instance groups
