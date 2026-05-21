# External Passthrough Network Load Balancer Module

This module allows managing a GCE Network Load Balancer and integrates the forwarding rule, regional backend, and optional health check resources. It's designed to be a simple match for the [`compute-vm`](../compute-vm) module, which can be used to manage instance templates and instance groups.

## Examples

- [Referencing existing MIGs](#referencing-existing-migs)
- [Externally manages instances](#externally-managed-instances)
- [End to end example](#end-to-end-example)

### Referencing existing MIGs

This example shows how to reference existing Managed Infrastructure Groups (MIGs).

```hcl
module "nlb" {
  source     = "./fabric/modules/net-lb-ext"
  project_id = var.project_id
  region     = var.region
  name       = "nlb-test"
  backends = [{
    group = module.compute-mig.group_manager.instance_group
  }]
  health_check_config = {
    http = {
      port = 80
    }
  }
}
# tftest modules=3 resources=5 fixtures=fixtures/compute-mig.tf inventory=migs.yaml e2e
```

### Externally managed instances

This examples shows how to create an NLB by combining externally managed instances (in a custom module or even outside of the current root module) in an unmanaged group. When using internally managed groups, remember to run `terraform apply` each time group instances change.

```hcl
module "nlb" {
  source     = "./fabric/modules/net-lb-ext"
  project_id = var.project_id
  region     = var.region
  name       = "nlb-test"
  group_configs = {
    my-group = {
      zone = "${var.region}-b"
      instances = [
        module.compute-vm-group-b.id,
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
# tftest modules=3 resources=8 fixtures=fixtures/compute-vm-group-bc.tf inventory=ext_migs.yaml e2e
```

### Multiple forwarding rules

You can add more forwarding rules to your load balancer and override some forwarding rules defaults, including the global access policy, the IP protocol, the IP version and ports.

The example adds two forwarding rules:

- the first one, called `nlb-test-vip-one` exposes an IPv4 address, it listens on all ports, and allows connections from any region.
- the second one, called `nlb-test-vip-two` exposes an IPv4 address, it listens on port 80 and allows connections from the same region only.

```hcl
module "nlb" {
  source     = "./fabric/modules/net-lb-ext"
  project_id = var.project_id
  region     = var.region
  name       = "nlb-test"
  backends = [{
    group = module.nlb.groups.my-group.self_link
  }]
  forwarding_rules_config = {
    vip-one = {}
    vip-two = {
      ports = [80]
    }
  }
  group_configs = {
    my-group = {
      zone = "${var.region}-b"
      instances = [
        module.compute-vm-group-b.id,
      ]
    }
  }
}
# tftest modules=3 resources=9 fixtures=fixtures/compute-vm-group-bc.tf inventory=fwd_rules.yaml e2e
```

### Dual stack (IPv4 and IPv6)

Your load balancer can use a combination of either or both IPv4 and IPv6 forwarding rules.
In this example we set the load balancer to work as dual stack, meaning it exposes both an IPv4 and an IPv6 address.

```hcl
module "nlb" {
  source     = "./fabric/modules/net-lb-ext"
  project_id = var.project_id
  region     = var.region
  name       = "nlb-test"
  backends = [{
    group = module.nlb.groups.my-group.self_link
  }]
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
      zone = "${var.region}-b"
      instances = [
        module.compute-vm-group-b.id,
      ]
    }
  }
}
# tftest modules=3 resources=9 fixtures=fixtures/compute-vm-group-bc.tf inventory=dual_stack.yaml e2e
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
  zone       = "${var.region}-${each.key}"
  name       = "nlb-test-${each.key}"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
  }]
  boot_disk = {
    initialize_params = {
      type = "pd-ssd"
      size = 10
    }
    source = {
      image = "projects/cos-cloud/global/images/family/cos-stable"
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
  region     = var.region
  name       = "nlb-test"
  backends = [
    for z, mod in module.instance-group : {
      group = mod.group.self_link
    }
  ]
  forwarding_rules_config = {
    "" = {
      ports = [80]
    }
  }
  health_check_config = {
    http = {
      port = 80
    }
  }
}
# tftest modules=3 resources=7 inventory=e2e.yaml e2e
```

## Deploying changes to load balancer configurations

For deploying changes to load balancer configuration please refer to [net-lb-app-ext README.md](../net-lb-app-ext/README.md#deploying-changes-to-load-balancer-configurations)
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L203) | Name used for all resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L208) | Project id where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L213) | GCP region. | <code>string</code> | ✓ |  |
| [backend_service_config](variables.tf#L17) | Backend service level configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [backends](variables.tf#L73) | Load balancer backends. | <code>list&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#91;&#93;</code> |
| [forwarding_rules_config](variables.tf#L84) | The optional forwarding rules configuration. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [group_configs](variables.tf#L100) | Optional unmanaged groups to create. Can be referenced in backends via outputs. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [health_check](variables.tf#L113) | Name of existing health check to use, disables auto-created health check. | <code>string</code> |  | <code>null</code> |
| [health_check_config](variables.tf#L119) | Optional auto-created health check configuration, use the output self-link to set it in the auto healing policy. Refer to examples for usage. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [labels](variables.tf#L197) | Labels set on resources. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [backend_service](outputs.tf#L17) | Backend resource. |  |
| [backend_service_id](outputs.tf#L22) | Backend id. |  |
| [backend_service_self_link](outputs.tf#L27) | Backend self link. |  |
| [forwarding_rule_addresses](outputs.tf#L32) | Forwarding rule addresses. |  |
| [forwarding_rule_self_links](outputs.tf#L40) | Forwarding rule self links. |  |
| [forwarding_rules](outputs.tf#L48) | Forwarding rule resources. |  |
| [group_self_links](outputs.tf#L53) | Optional unmanaged instance group self links. |  |
| [groups](outputs.tf#L60) | Optional unmanaged instance group resources. |  |
| [health_check](outputs.tf#L65) | Auto-created health-check resource. |  |
| [health_check_id](outputs.tf#L70) | Auto-created health-check id. |  |
| [health_check_self_link](outputs.tf#L75) | Auto-created health-check self link. |  |
| [id](outputs.tf#L80) | Fully qualified forwarding rule ids. |  |

## Fixtures

- [compute-mig.tf](../../tests/fixtures/compute-mig.tf)
- [compute-vm-group-bc.tf](../../tests/fixtures/compute-vm-group-bc.tf)
<!-- END TFDOC -->
