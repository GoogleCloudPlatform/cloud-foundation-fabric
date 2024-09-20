# Internal Passthrough Network Load Balancer Module

This module allows managing a GCE Internal Load Balancer and integrates the forwarding rule, regional backend, and optional health check resources. It's designed to be a simple match for the [`compute-vm`](../compute-vm) module, which can be used to manage instance templates and instance groups.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Referencing existing MIGs](#referencing-existing-migs)
  - [Externally managed instances](#externally-managed-instances)
  - [Passing multiple protocols through the load balancers](#passing-multiple-protocols-through-the-load-balancers)
  - [Multiple forwarding rules](#multiple-forwarding-rules)
  - [Dual stack (IPv4 and IPv6)](#dual-stack-ipv4-and-ipv6)
  - [PSC service attachments](#psc-service-attachments)
  - [End to end example](#end-to-end-example)
- [Deploying changes to load balancer configurations](#deploying-changes-to-load-balancer-configurations)
- [Issues](#issues)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

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

module "ilb" {
  source        = "./fabric/modules/net-lb-int"
  project_id    = var.project_id
  region        = "europe-west1"
  name          = "ilb-test"
  service_label = "ilb-test"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
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

This examples shows how to create an ILB by combining externally managed instances (in a custom module or even outside of the current root module) in an unmanaged group. When using internally managed groups, remember to run `terraform apply` each time group instances change.

```hcl
module "ilb" {
  source        = "./fabric/modules/net-lb-int"
  project_id    = var.project_id
  region        = "europe-west1"
  name          = "ilb-test"
  service_label = "ilb-test"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
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
    group = module.ilb.groups.my-group.self_link
  }]
  health_check_config = {
    http = {
      port = 80
    }
  }
}
# tftest modules=1 resources=4
```

### Passing multiple protocols through the load balancers

The example shows how to send multiple protocols through the same internal network passthrough load balancer.

```hcl
module "ilb" {
  source        = "./fabric/modules/net-lb-int"
  project_id    = var.project_id
  region        = "europe-west1"
  name          = "ilb-test"
  service_label = "ilb-test"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
  forwarding_rules_config = {
    "" = {
      protocol = "L3_DEFAULT"
    }
  }
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
    group = module.ilb.groups.my-group.self_link
  }]
}
# tftest modules=1 resources=4
```

### Multiple forwarding rules

You can add more forwarding rules to your load balancer and override some forwarding rules defaults, including the global access policy, the IP protocol, the IP version and ports.

The example adds two forwarding rules:

- the first one, called `ilb-test-vip-one` exposes an IPv4 address, it listens on all ports, and allows connections from any region.
- the second one, called `ilb-test-vip-two` exposes an IPv4 address, it listens on port 80 and allows connections from the same region only.

```hcl
module "ilb" {
  source        = "./fabric/modules/net-lb-int"
  project_id    = var.project_id
  region        = "europe-west1"
  name          = "ilb-test"
  service_label = "ilb-test"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
  forwarding_rules_config = {
    vip-one = {}
    vip-two = {
      global_access = false
      ports         = [80]
    }
  }
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
    group = module.ilb.groups.my-group.self_link
  }]
}
# tftest modules=1 resources=5
```

### Dual stack (IPv4 and IPv6)

Your load balancer can use a combination of either or both IPv4 and IPv6 forwarding rules.
In this example we set the load balancer to work as dual stack, meaning it exposes both an IPv4 and an IPv6 address.

```hcl
module "ilb" {
  source        = "./fabric/modules/net-lb-int"
  project_id    = var.project_id
  region        = "europe-west1"
  name          = "ilb-test"
  service_label = "ilb-test"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
  forwarding_rules_config = {
    ipv4 = {
      version = "IPV4"
    }
    ipv6 = {
      version = "IPV6"
    }
  }
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
    group = module.ilb.groups.my-group.self_link
  }]
}
# tftest modules=1 resources=5
```

### PSC service attachments

The optional `service_attachments` variable allows [publishing Private Service Connect services](https://cloud.google.com/vpc/docs/configure-private-service-connect-producer) by configuring  up to one service attachment for each of the forwarding rules.

```hcl
module "ilb" {
  source        = "./fabric/modules/net-lb-int"
  project_id    = var.project_id
  region        = "europe-west1"
  name          = "ilb-test"
  service_label = "ilb-test"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
  forwarding_rules_config = {
    vip-one = {}
    vip-two = {
      global_access = false
      ports         = [80]
    }
  }
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
    group = module.ilb.groups.my-group.self_link
  }]
  service_attachments = {
    vip-one = {
      nat_subnets          = [var.subnet_psc_1.self_link]
      automatic_connection = true
    }
    vip-two = {
      nat_subnets          = [var.subnet_psc_2.self_link]
      automatic_connection = true
    }
  }
}
# tftest modules=1 resources=7
```

### End to end example

This example spins up a simple HTTP server and combines four modules:

- [`nginx`](../cloud-config-container/nginx) from the `cloud-config-container` collection, to manage instance configuration
- [`compute-vm`](../compute-vm) to manage the instance template and unmanaged instance group
- this module to create an Internal Load Balancer in front of the managed instance group

Note that the example uses the GCE default service account. You might want to create an ad-hoc service account by combining the [`iam-service-account`](../iam-service-account) module, or by having the GCE VM module create one for you. In both cases, remember to set at least logging write permissions for the service account, or the container on the instances won't be able to start.

```hcl
module "cos-nginx" {
  source = "./fabric/modules/cloud-config-container/nginx"
}

module "instance-group" {
  source     = "./fabric/modules/compute-vm"
  for_each   = toset(["b", "c"])
  project_id = var.project_id
  zone       = "${var.region}-${each.key}"
  name       = "ilb-test-${each.key}"
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

module "ilb" {
  source        = "./fabric/modules/net-lb-int"
  project_id    = var.project_id
  region        = var.region
  name          = "ilb-test"
  service_label = "ilb-test"
  vpc_config = {
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
  }
  forwarding_rules_config = {
    "" = {
      ports = [80]
    }
  }
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
# tftest modules=3 resources=7 e2e
```

## Deploying changes to load balancer configurations
For deploying changes to load balancer configuration please refer to [net-lb-app-ext README.md](../net-lb-app-ext/README.md#deploying-changes-to-load-balancer-configurations)


## Issues

There are some corner cases where Terraform raises a cycle error on apply, for example when using the entire ILB module as a value in `for_each` counts used to create static routes in the VPC module. These are easily fixed by using forwarding rule ids instead of modules as values in the `for_each` loop.

<!--
One other issue is a `Provider produced inconsistent final plan` error which is sometimes raised when switching template version. This seems to be related to this [open provider issue](https://github.com/terraform-providers/terraform-provider-google/issues/3937), but it's relatively harmless since the resource is updated, and subsequent applies raise no errors.
-->
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L187) | Name used for all resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L192) | Project id where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L197) | GCP region. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L223) | VPC-level configuration. | <code title="object&#40;&#123;&#10;  network    &#61; string&#10;  subnetwork &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [backend_service_config](variables.tf#L17) | Backend service level configuration. | <code title="object&#40;&#123;&#10;  connection_draining_timeout_sec &#61; optional&#40;number&#41;&#10;  connection_tracking &#61; optional&#40;object&#40;&#123;&#10;    idle_timeout_sec          &#61; optional&#40;number&#41;&#10;    persist_conn_on_unhealthy &#61; optional&#40;string&#41;&#10;    track_per_session         &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  enable_subsetting &#61; optional&#40;bool&#41;&#10;  failover_config &#61; optional&#40;object&#40;&#123;&#10;    disable_conn_drain        &#61; optional&#40;bool&#41;&#10;    drop_traffic_if_unhealthy &#61; optional&#40;bool&#41;&#10;    ratio                     &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  log_sample_rate  &#61; optional&#40;number&#41;&#10;  name             &#61; optional&#40;string&#41;&#10;  protocol         &#61; optional&#40;string, &#34;UNSPECIFIED&#34;&#41;&#10;  session_affinity &#61; optional&#40;string&#41;&#10;  timeout_sec      &#61; optional&#40;number&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [backends](variables.tf#L52) | Load balancer backends. | <code title="list&#40;object&#40;&#123;&#10;  group       &#61; string&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  failover    &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;&#41;">list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [description](variables.tf#L63) | Optional description used for resources. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [forwarding_rules_config](variables.tf#L69) | The optional forwarding rules configuration. | <code title="map&#40;object&#40;&#123;&#10;  address       &#61; optional&#40;string&#41;&#10;  description   &#61; optional&#40;string&#41;&#10;  global_access &#61; optional&#40;bool, true&#41;&#10;  ip_version    &#61; optional&#40;string&#41;&#10;  name          &#61; optional&#40;string&#41;&#10;  ports         &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;  protocol      &#61; optional&#40;string, &#34;TCP&#34;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  &#34;&#34; &#61; &#123;&#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [group_configs](variables.tf#L85) | Optional unmanaged groups to create. Can be referenced in backends via outputs. | <code title="map&#40;object&#40;&#123;&#10;  zone        &#61; string&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  instances   &#61; optional&#40;list&#40;string&#41;&#41;&#10;  named_ports &#61; optional&#40;map&#40;number&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check](variables.tf#L97) | Name of existing health check to use, disables auto-created health check. | <code>string</code> |  | <code>null</code> |
| [health_check_config](variables.tf#L103) | Optional auto-created health check configuration, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code title="object&#40;&#123;&#10;  check_interval_sec  &#61; optional&#40;number&#41;&#10;  description         &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  enable_logging      &#61; optional&#40;bool, false&#41;&#10;  healthy_threshold   &#61; optional&#40;number&#41;&#10;  name                &#61; optional&#40;string&#41;&#10;  timeout_sec         &#61; optional&#40;number&#41;&#10;  unhealthy_threshold &#61; optional&#40;number&#41;&#10;  grpc &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    service_name       &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  http &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  http2 &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  https &#61; optional&#40;object&#40;&#123;&#10;    host               &#61; optional&#40;string&#41;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request_path       &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  tcp &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request            &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  ssl &#61; optional&#40;object&#40;&#123;&#10;    port               &#61; optional&#40;number&#41;&#10;    port_name          &#61; optional&#40;string&#41;&#10;    port_specification &#61; optional&#40;string&#41; &#35; USE_FIXED_PORT USE_NAMED_PORT USE_SERVING_PORT&#10;    proxy_header       &#61; optional&#40;string&#41;&#10;    request            &#61; optional&#40;string&#41;&#10;    response           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  tcp &#61; &#123;&#10;    port_specification &#61; &#34;USE_SERVING_PORT&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [labels](variables.tf#L181) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_attachments](variables.tf#L202) | PSC service attachments, keyed by forwarding rule. | <code title="map&#40;object&#40;&#123;&#10;  nat_subnets           &#61; list&#40;string&#41;&#10;  automatic_connection  &#61; optional&#40;bool, false&#41;&#10;  consumer_accept_lists &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  consumer_reject_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;  description           &#61; optional&#40;string&#41;&#10;  domain_name           &#61; optional&#40;string&#41;&#10;  enable_proxy_protocol &#61; optional&#40;bool, false&#41;&#10;  reconcile_connections &#61; optional&#40;bool&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [service_label](variables.tf#L217) | Optional prefix of the fully qualified forwarding rule name. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [backend_service](outputs.tf#L17) | Backend resource. | ✓ |
| [backend_service_id](outputs.tf#L23) | Backend id. |  |
| [backend_service_self_link](outputs.tf#L28) | Backend self link. |  |
| [forwarding_rule_addresses](outputs.tf#L33) | Forwarding rule address. |  |
| [forwarding_rule_self_links](outputs.tf#L41) | Forwarding rule self links. |  |
| [forwarding_rules](outputs.tf#L49) | Forwarding rule resources. |  |
| [group_self_links](outputs.tf#L57) | Optional unmanaged instance group self links. |  |
| [groups](outputs.tf#L64) | Optional unmanaged instance group resources. |  |
| [health_check](outputs.tf#L69) | Auto-created health-check resource. |  |
| [health_check_id](outputs.tf#L74) | Auto-created health-check id. |  |
| [health_check_self_link](outputs.tf#L79) | Auto-created health-check self link. |  |
| [id](outputs.tf#L84) | Fully qualified forwarding rule ids. |  |
| [service_attachment_ids](outputs.tf#L92) | Service attachment ids. |  |
<!-- END TFDOC -->
