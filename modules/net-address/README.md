# Net Address Reservation Module

This module allows reserving Compute Engine external, global, and internal addresses. The module also supports managing VPC network attachments from service projects.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [External and global addresses](#external-and-global-addresses)
  - [Internal addresses](#internal-addresses)
  - [IPv6 addresses](#ipv6-addresses)
  - [PSA addresses](#psa-addresses)
  - [PSC addresses](#psc-addresses)
  - [IPSec Interconnect addresses](#ipsec-interconnect-addresses)
  - [PSC Network Attachments](#psc-network-attachments)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

## Examples

### External and global addresses

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  external_addresses = {
    one = { region = "europe-west1" }
    two = {
      region = "europe-west2"
      tier   = "STANDARD"
    }
  }
  global_addresses = {
    app-1 = {}
    app-2 = {}
  }
}
# tftest modules=1 resources=4 inventory=external.yaml e2e
```

### Internal addresses

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  internal_addresses = {
    ilb-1 = {
      purpose    = "SHARED_LOADBALANCER_VIP"
      region     = var.region
      subnetwork = var.subnet.self_link
    }
    ilb-2 = {
      address    = "10.0.16.102"
      region     = var.region
      subnetwork = var.subnet.self_link
    }
  }
}
# tftest modules=1 resources=2 inventory=internal.yaml e2e
```

### IPv6 addresses

You can reserve both external and internal IPv6 addresses.

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  external_addresses = {
    nlb = {
      region     = var.region
      subnetwork = module.vpc.subnets["${var.region}/ipv6-external"].self_link
      ipv6 = {
        endpoint_type = "NETLB"
      }
    }
  }
  internal_addresses = {
    vm = {
      ipv6       = {}
      region     = var.region
      subnetwork = module.vpc.subnets["${var.region}/ipv6-internal"].self_link
    }
  }
}
# tftest modules=2 resources=7 fixtures=fixtures/net-vpc-ipv6.tf inventory=ipv6.yaml e2e
```

### PSA addresses

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  psa_addresses = {
    cloudsql-mysql = {
      address       = "10.10.10.0"
      network       = var.vpc.self_link
      prefix_length = 24
    }
  }
}
# tftest modules=1 resources=1 inventory=psa.yaml e2e
```

### PSC addresses

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  psc_addresses = {
    one = {
      address = "10.0.0.32"
      network = var.vpc.self_link
    }
  }
}
# tftest modules=1 resources=1 inventory=psc.yaml e2e
```

To create PSC address targeting a service regional provider use the `service_attachment` property.
```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  psc_addresses = {
    cloudsql-one = {
      address          = "10.0.16.32"
      subnet_self_link = var.subnet.self_link
      region           = var.region
      service_attachment = {
        psc_service_attachment_link = module.cloudsql-instance.psc_service_attachment_link
      }
    }
  }
}
# tftest modules=2 resources=3 fixtures=fixtures/cloudsql-instance.tf inventory=psc-service-attachment.yaml e2e
```

Specify `vpc-sc` or `all-apis` in `psc_service_attachment_link` to targe Google APIs.
```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  psc_addresses = {
    googleapis = {
      address = "10.0.32.32"
      network = var.vpc.self_link
      service_attachment = {
        psc_service_attachment_link = "all-apis"
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=psc-service-attachment-all-apis.yaml e2e
```

Set `global_access` to true to enable global access for regional addresses used by a service attachment.

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  psc_addresses = {
    cloudsql-one = {
      address          = "10.0.16.32"
      subnet_self_link = var.subnet.self_link
      region           = var.region
      service_attachment = {
        psc_service_attachment_link = module.cloudsql-instance.psc_service_attachment_link
        global_access               = true
      }
    }
  }
}
# tftest modules=2 resources=3 fixtures=fixtures/cloudsql-instance.tf inventory=psc-global.yaml e2e
```



### IPSec Interconnect addresses

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  ipsec_interconnect_addresses = {
    vpn-gw-range-1 = {
      address       = "10.255.255.0"
      region        = var.region
      network       = var.vpc.self_link
      prefix_length = 29
    }
    vpn-gw-range-2 = {
      address       = "10.255.255.8"
      region        = var.region
      network       = var.vpc.self_link
      prefix_length = 29
    }
  }
}
# tftest modules=1 resources=2 inventory=ipsec-interconnect.yaml e2e
```

### PSC Network Attachments

The project where the network attachment is created must be either the VPC project, or a Shared VPC service project of the host owning the VPC.

```hcl
module "addresses" {
  source     = "./fabric/modules/net-address"
  project_id = var.project_id
  network_attachments = {
    gce-0 = {
      subnet_self_link = (
        "projects/net-host/regions/europe-west8/subnetworks/gce"
      )
      producer_accept_lists = [var.project_id]
    }
  }
}
# tftest modules=1 resources=1 inventory=network-attachments.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L97) | Project where the addresses will be created. | <code>string</code> | ✓ |  |
| [external_addresses](variables.tf#L17) | Map of external addresses, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;  region      &#61; string&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  ipv6 &#61; optional&#40;object&#40;&#123;&#10;    endpoint_type &#61; string&#10;  &#125;&#41;&#41;&#10;  labels     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  name       &#61; optional&#40;string&#41;&#10;  subnetwork &#61; optional&#40;string&#41; &#35; for IPv6&#10;  tier       &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [global_addresses](variables.tf#L40) | List of global addresses to create. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  ipv6        &#61; optional&#40;map&#40;string&#41;&#41; &#35; To be left empty for ipv6&#10;  name        &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [internal_addresses](variables.tf#L50) | Map of internal addresses to create, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;  region      &#61; string&#10;  subnetwork  &#61; string&#10;  address     &#61; optional&#40;string&#41;&#10;  description &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  ipv6        &#61; optional&#40;map&#40;string&#41;&#41; &#35; To be left empty for ipv6&#10;  labels      &#61; optional&#40;map&#40;string&#41;&#41;&#10;  name        &#61; optional&#40;string&#41;&#10;  purpose     &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ipsec_interconnect_addresses](variables.tf#L65) | Map of internal addresses used for HPA VPN over Cloud Interconnect. | <code title="map&#40;object&#40;&#123;&#10;  region        &#61; string&#10;  address       &#61; string&#10;  network       &#61; string&#10;  description   &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  name          &#61; optional&#40;string&#41;&#10;  prefix_length &#61; number&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [network_attachments](variables.tf#L84) | PSC network attachments, names as keys. | <code title="map&#40;object&#40;&#123;&#10;  subnet_self_link      &#61; string&#10;  automatic_connection  &#61; optional&#40;bool, false&#41;&#10;  description           &#61; optional&#40;string, &#34;Terraform-managed.&#34;&#41;&#10;  producer_accept_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;  producer_reject_lists &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [psa_addresses](variables.tf#L102) | Map of internal addresses used for Private Service Access. | <code title="map&#40;object&#40;&#123;&#10;  address       &#61; string&#10;  network       &#61; string&#10;  prefix_length &#61; number&#10;  description   &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  name          &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [psc_addresses](variables.tf#L114) | Map of internal addresses used for Private Service Connect. | <code title="map&#40;object&#40;&#123;&#10;  address          &#61; string&#10;  description      &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;  name             &#61; optional&#40;string&#41;&#10;  network          &#61; optional&#40;string&#41;&#10;  region           &#61; optional&#40;string&#41;&#10;  subnet_self_link &#61; optional&#40;string&#41;&#10;  service_attachment &#61; optional&#40;object&#40;&#123; &#35; so we can safely check if service_attachemnt &#33;&#61; null in for_each&#10;    psc_service_attachment_link &#61; string&#10;    global_access               &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [external_addresses](outputs.tf#L17) | Allocated external addresses. |  |
| [global_addresses](outputs.tf#L25) | Allocated global external addresses. |  |
| [internal_addresses](outputs.tf#L33) | Allocated internal addresses. |  |
| [ipsec_interconnect_addresses](outputs.tf#L41) | Allocated internal addresses for HA VPN over Cloud Interconnect. |  |
| [network_attachment_ids](outputs.tf#L49) | IDs of network attachments. |  |
| [psa_addresses](outputs.tf#L57) | Allocated internal addresses for PSA endpoints. |  |
| [psc_addresses](outputs.tf#L65) | Allocated internal addresses for PSC endpoints. |  |

## Fixtures

- [cloudsql-instance.tf](../../tests/fixtures/cloudsql-instance.tf)
- [net-vpc-ipv6.tf](../../tests/fixtures/net-vpc-ipv6.tf)
<!-- END TFDOC -->
