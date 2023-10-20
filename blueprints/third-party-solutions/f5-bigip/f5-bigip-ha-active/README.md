# F5 BigIP-VE HA active-active blueprint

This blueprint allows to create external active/active private and/or public F5 BigIP-VE load balancers.

## Design notes

- The blueprint supports by default two VPCs: a `dataplane` network and a `management` network. 
- We don't use the `F5 Cloud Failover Extension (CFE)`. This would imply an active/passive architecture, it would limit the number of instances to two, it would use static routes and it would require F5 VMs service accounts to have roles set, so they can configure routes.
- We deploy instead as many active instances users need and we make them reachable through passthrough GCP load balancers.
- The blueprint allows to expose the F5 instances both externally and internally, using internal and external passthrough load balancers. You can also choose to expose the same F5 instances both externally and internally at the same time.
- The blueprint supports dual-stack (IPv4/IPv6).
- We deliberately use the original F5-BigIP `startup-script.tpl` file. We haven't changed it and we pass to it the same variables, so it should be easier to swap it with custom scripts.

## Examples

<!-- BEGIN TOC -->
- [Design notes](#design-notes)
- [Examples](#examples)
  - [Single instance](#single-instance)
  - [Active/active instances](#activeactive-instances)
  - [Public load F5 load balancers](#public-load-f5-load-balancers)
  - [Multiple forwarding rules and dual-stack (IPv4/IPv6)](#multiple-forwarding-rules-and-dual-stack-ipv4ipv6)
  - [Use the GCP secret manager](#use-the-gcp-secret-manager)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

### Single instance

By default, the blueprint deploys one or more instances in a region. These instances are behind an internal network passthrough (L3_DEFAULT) load balancer.

```hcl
module "f5-lb" {
  source     = "./fabric/blueprints/third-party-solutions/f5-bigip/f5-bigip-ha-active"
  project_id = "my-project"
  prefix     = "test"
  region     = "europe-west1"

  f5_vms_dedicated_config = {
    a = {
      license_key = "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE"
      network_config = {
        alias_ip_range_address = "192.168.1.0/24"
        alias_ip_range_name    = "ip-range-a"
      }
    }
  }

  vpc_config = {
    dataplane = {
      network    = "projects/my-project/global/networks/dataplane"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/dataplane"
    }
    management = {
      network    = "projects/my-project/global/networks/management"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/management"
    }
  }
}
# tftest modules=6 resources=8 inventory=single-instance.yaml
```

### Active/active instances

To add more than one instance, add items to the `f5_vms_dedicated_config` variable. Keys specify the the zones where the instances are deployed.

```hcl
module "f5-lb" {
  source     = "./fabric/blueprints/third-party-solutions/f5-bigip/f5-bigip-ha-active"
  project_id = "my-project"
  prefix     = "test"
  region     = "europe-west1"

  f5_vms_dedicated_config = {
    a = {
      license_key = "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE"
      network_config = {
        alias_ip_range_address = "192.168.1.0/24"
        alias_ip_range_name    = "ip-range-a"
      }
    }
    b = {
      license_key = "XXXXX-YYYYY-WWWWW-ZZZZZ-PPPPPP"
      network_config = {
        alias_ip_range_address = "192.168.2.0/24"
        alias_ip_range_name    = "ip-range-b"
      }
    }
  }

  vpc_config = {
    dataplane = {
      network    = "projects/my-project/global/networks/dataplane"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/dataplane"
    }
    management = {
      network    = "projects/my-project/global/networks/management"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/management"
    }
  }
}
# tftest modules=7 resources=12 inventory=active-active-instances.yaml
```

### Public load F5 load balancers

You can configure the blueprint so it deploys external network passthrough load balancers, so you can expose on Internet your F5 load balancer(s).

```hcl
module "f5-lb" {
  source     = "./fabric/blueprints/third-party-solutions/f5-bigip/f5-bigip-ha-active"
  project_id = "my-project"
  prefix     = "test"
  region     = "europe-west1"

  f5_vms_dedicated_config = {
    a = {
      license_key = "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE"
      network_config = {
        alias_ip_range_address = "192.168.1.0/24"
        alias_ip_range_name    = "ip-range-a"
      }
    }
    b = {
      license_key = "XXXXX-YYYYY-WWWWW-ZZZZZ-PPPPPP"
      network_config = {
        alias_ip_range_address = "192.168.2.0/24"
        alias_ip_range_name    = "ip-range-b"
      }
    }
  }

  forwarding_rules_config = {
    "ext-ipv4" = {
      external = true
    }
  }

  vpc_config = {
    dataplane = {
      network    = "projects/my-project/global/networks/dataplane"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/dataplane"
    }
    management = {
      network    = "projects/my-project/global/networks/management"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/management"
    }
  }
}
# tftest modules=7 resources=12 inventory=public-load-balancers.yaml
```

### Multiple forwarding rules and dual-stack (IPv4/IPv6)

You can configure the blueprint in order to expose both internal and external load balancers.
Each load balancer can have multiple forwarding rules, eventually both IPv4 and IPv6.

```hcl
module "f5-lb" {
  source     = "./fabric/blueprints/third-party-solutions/f5-bigip/f5-bigip-ha-active"
  project_id = "my-project"
  prefix     = "test"
  region     = "europe-west1"

  f5_vms_dedicated_config = {
    a = {
      license_key = "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE"
      network_config = {
        alias_ip_range_address = "192.168.1.0/24"
        alias_ip_range_name    = "ip-range-a"
      }
    }
    b = {
      license_key = "XXXXX-YYYYY-WWWWW-ZZZZZ-PPPPPP"
      network_config = {
        alias_ip_range_address = "192.168.2.0/24"
        alias_ip_range_name    = "ip-range-b"
      }
    }
  }

  forwarding_rules_config = {
    "ext-ipv4" = {
      external = true
    }
    "ext-ipv6" = {
      external   = true
      ip_version = "IPV6"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/ipv6_external"
    }
    "int-ipv4" = {}
    "int-ipv6" = {
      ip_version = "IPV6"
    }
  }

  vpc_config = {
    dataplane = {
      network    = "projects/my-project/global/networks/dataplane"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/dataplane"
    }
    management = {
      network    = "projects/my-project/global/networks/management"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/management"
    }
  }
}
# tftest modules=8 resources=20 inventory=multiple-fw-rules.yaml
```

### Use the GCP secret manager

By default, this blueprint (and the `startup-script.tpl`) stores the F5 admin password in plain-text as a metadata of the F5 VMs. Most of administrators change this password in F5 soon after the boot.
The example shows how to leverage instead the GCP secret manager.

```hcl
module "f5-lb" {
  source     = "./fabric/blueprints/third-party-solutions/f5-bigip/f5-bigip-ha-active"
  project_id = "my-project"
  prefix     = "test"
  region     = "europe-west1"

  f5_vms_shared_config = {
    secret         = "f5_secret_name" # needs to be in the same project
    use_gcp_secret = true
  }

  f5_vms_dedicated_config = {
    a = {
      license_key = "AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE"
      network_config = {
        alias_ip_range_address = "192.168.1.0/24"
        alias_ip_range_name    = "ip-range-a"
      }
    }
  }

  vpc_config = {
    dataplane = {
      network    = "projects/my-project/global/networks/dataplane"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/dataplane"
    }
    management = {
      network    = "projects/my-project/global/networks/management"
      subnetwork = "projects/my-project/regions/europe-west1/subnetworks/management"
    }
  }
}
# tftest modules=6 resources=8 inventory=secret-manager.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [f5_vms_dedicated_config](variables.tf#L17) | The F5 VMs configuration. The map keys are the zones where the VMs are deployed. | <code title="map&#40;object&#40;&#123;&#10;  network_config &#61; object&#40;&#123;&#10;    alias_ip_range_address &#61; string&#10;    alias_ip_range_name    &#61; string&#10;    dataplane_address      &#61; optional&#40;string&#41;&#10;    management_address     &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#10;  license_key &#61; optional&#40;string, &#34;AAAAA-BBBBB-CCCCC-DDDDD-EEEEEEE&#34;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> | ✓ |  |
| [prefix](variables.tf#L73) | The name prefix used for resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L78) | The project id where we deploy the resources. | <code>string</code> | ✓ |  |
| [region](variables.tf#L83) | The region where we deploy the F5 IPs. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L88) | The dataplane and mgmt network and subnetwork self links. | <code title="object&#40;&#123;&#10;  dataplane &#61; object&#40;&#123;&#10;    network    &#61; string&#10;    subnetwork &#61; string&#10;  &#125;&#41;&#10;  management &#61; object&#40;&#123;&#10;    network    &#61; string&#10;    subnetwork &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [f5_vms_shared_config](variables.tf#L30) | The F5 VMs shared configurations. | <code title="object&#40;&#123;&#10;  disk_size       &#61; optional&#40;number, 100&#41;&#10;  enable_ipv6     &#61; optional&#40;bool, false&#41; &#35; needs to be true to receive traffic from IPv6 forwarding rules&#10;  image           &#61; optional&#40;string, &#34;projects&#47;f5-7626-networks-public&#47;global&#47;images&#47;f5-bigip-15-1-2-1-0-0-10-byol-ltm-2boot-loc-210115160742&#34;&#41;&#10;  instance_type   &#61; optional&#40;string, &#34;n2-standard-4&#34;&#41;&#10;  secret          &#61; optional&#40;string, &#34;mysecret&#34;&#41;&#10;  service_account &#61; optional&#40;string&#41;&#10;  ssh_public_key  &#61; optional&#40;string, &#34;my_key.pub&#34;&#41;&#10;  tags            &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  use_gcp_secret  &#61; optional&#40;bool, false&#41;&#10;  username        &#61; optional&#40;string, &#34;admin&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [forwarding_rules_config](variables.tf#L47) | The optional configurations of the GCP load balancers forwarding rules. | <code title="map&#40;object&#40;&#123;&#10;  address       &#61; optional&#40;string&#41;&#10;  external      &#61; optional&#40;bool, false&#41;&#10;  global_access &#61; optional&#40;bool, true&#41;&#10;  ip_version    &#61; optional&#40;string, &#34;IPV4&#34;&#41;&#10;  protocol      &#61; optional&#40;string, &#34;L3_DEFAULT&#34;&#41;&#10;  subnetwork    &#61; optional&#40;string&#41; &#35; used for IPv6 NLBs&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code title="&#123;&#10;  l4 &#61; &#123;&#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [health_check_config](variables.tf#L62) | The optional health check configuration. | <code>map&#40;any&#41;</code> |  | <code title="&#123;&#10;  tcp &#61; &#123;&#10;    port               &#61; 65535&#10;    port_specification &#61; &#34;USE_FIXED_PORT&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [f5_management_ips](outputs.tf#L17) | The F5 management interfaces IP addresses. |  |
| [forwarding_rules_config](outputs.tf#L25) | The GCP forwarding rules configurations. |  |
<!-- END TFDOC -->
