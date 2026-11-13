# VLAN Attachment module

This module allows for the provisioning of [HA VPN over Interconnect](https://cloud.google.com/network-connectivity/docs/interconnect/concepts/ha-vpn-interconnect?hl=it). Specifically, this module creates a VPN gateway, a configurable number of tunnels, and all the resources required to established IPSec and BGP with the peer routers.

The required pair of encrypted VLAN Attachments can be created leveraging the [net-vlan-attachment](../net-vlan-attachment/) module.

## Examples

### Single region setup

```hcl
resource "google_compute_router" "encrypted-interconnect-overlay-router" {
  name    = "encrypted-interconnect-overlay-router"
  project = "myproject"
  network = "mynet"
  region  = "europe-west8"
  bgp {
    asn               = 64514
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = "10.255.255.0/24"
    }
    advertised_ip_ranges {
      range = "192.168.255.0/24"
    }
  }
}

resource "google_compute_external_vpn_gateway" "default" {
  name        = "peer-vpn-gateway"
  project     = "myproject"
  description = "Peer IPSec over Interconnect VPN gateway"
  interface {
    id         = 0
    ip_address = "10.0.0.1"
  }
  interface {
    id         = 1
    ip_address = "10.0.0.2"
  }
}

module "vpngw-a" {
  source     = "./fabric/modules/net-ipsec-over-interconnect"
  project_id = "myproject"
  network    = "mynet"
  region     = "europe-west8"
  name       = "vpngw-a"
  interconnect_attachments = {
    a = "attach-01"
    b = "attach-02"
  }
  peer_gateway_config = {
    create = false
    id     = google_compute_external_vpn_gateway.default.id
  }
  router_config = {
    create = false
    name   = google_compute_router.encrypted-interconnect-overlay-router.name
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
        # MD5 Authentication is optional
        md5_authentication_key = {
          name = "foo"
          key  = "bar"
        }
      }
      bgp_session_range = "169.254.1.1/30"
      shared_secret = {
        value      = "foobar"
        wo_version = 1
      }
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.1.6"
        asn     = 64514
      }
      bgp_session_range = "169.254.1.5/30"
      shared_secret = {
        value      = "foobar"
        wo_version = 1
      }
      vpn_gateway_interface = 1
    }
    remote-2 = {
      bgp_peer = {
        address = "169.254.1.10"
        asn     = 64514
      }
      bgp_session_range = "169.254.1.9/30"
      shared_secret = {
        value      = "foobar"
        wo_version = 1
      }
      vpn_gateway_interface = 0
    }
    remote-3 = {
      bgp_peer = {
        address = "169.254.1.14"
        asn     = 64514
      }
      bgp_session_range = "169.254.1.13/30"
      shared_secret = {
        value      = "foobar"
        wo_version = 1
      }
      vpn_gateway_interface = 1
    }
  }
}
# tftest modules=1 resources=16 inventory=single-region.yaml
```

### Single region setup with BGP Route Policies

```hcl
resource "google_compute_router" "encrypted-interconnect-overlay-router" {
  name    = "encrypted-interconnect-overlay-router"
  project = "myproject"
  network = "mynet"
  region  = "europe-west8"
  bgp {
    asn               = 64514
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]
    advertised_ip_ranges {
      range = "10.255.255.0/24"
    }
    advertised_ip_ranges {
      range = "192.168.255.0/24"
    }
  }
}

resource "google_compute_external_vpn_gateway" "default" {
  name        = "peer-vpn-gateway"
  project     = "myproject"
  description = "Peer IPSec over Interconnect VPN gateway"
  interface {
    id         = 0
    ip_address = "10.0.0.1"
  }
  interface {
    id         = 1
    ip_address = "10.0.0.2"
  }
}

module "vpngw-a" {
  source     = "./fabric/modules/net-ipsec-over-interconnect"
  project_id = "myproject"
  network    = "mynet"
  region     = "europe-west8"
  name       = "vpngw-a"
  interconnect_attachments = {
    a = "attach-01"
    b = "attach-02"
  }
  peer_gateway_config = {
    create = false
    id     = google_compute_external_vpn_gateway.default.id
  }
  router_config = {
    create = false
    name   = google_compute_router.encrypted-interconnect-overlay-router.name
    route_policies = {
      "import-rfc1918" = {
        type = "IMPORT"
        terms = [
          {
            priority = 1
            match = {
              expression  = "destination == '10.0.0.0/8' || destination == '172.16.0.0/12' || destination == '192.168.0.0/16'"
              title       = "import-rfc1918-subnets"
              description = "Accept the 3 RFC1918 subnets."
            }
            actions = [{
              expression = "accept()"
            }]
          }
        ]
      }
      "import-drop-all" = {
        type = "IMPORT"
        terms = [
          {
            priority = 2
            match = {
              expression  = "destination.inAnyRange(prefix('0.0.0.0/0').orLonger())"
              title       = "default-drop"
              description = "Drop all the routes not accepted above"
            }
            actions = [{
              expression = "drop()"
            }]
          }
        ]
      }
      "export-policy" = {
        type = "EXPORT"
        terms = [
          {
            priority = 0
            match = {
              expression = "destination == '10.255.255.0/24'"
            }
            actions = [
              { expression = "med.set(1000)" },
              { expression = "accept()" }
            ]
          }
        ]
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address         = "169.254.1.2"
        asn             = 64514
        import_policies = ["import-rfc1918", "import-drop-all"]
        export_policies = ["export-policy"]
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = { value = "foobar" }
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address         = "169.254.1.6"
        asn             = 64514
        import_policies = ["import-rfc1918", "import-drop-all"]
        export_policies = ["export-policy"]
      }
      bgp_session_range     = "169.254.1.5/30"
      shared_secret         = { value = "foobar" }
      vpn_gateway_interface = 1
    }
    remote-2 = {
      bgp_peer = {
        address         = "169.254.1.10"
        asn             = 64514
        import_policies = ["import-rfc1918", "import-drop-all"]
        export_policies = ["export-policy"]
      }
      bgp_session_range     = "169.254.1.9/30"
      shared_secret         = { value = "foobar" }
      vpn_gateway_interface = 0
    }
    remote-3 = {
      bgp_peer = {
        address         = "169.254.1.14"
        asn             = 64514
        import_policies = ["import-rfc1918", "import-drop-all"]
        export_policies = ["export-policy"]
      }
      bgp_session_range     = "169.254.1.13/30"
      shared_secret         = { value = "foobar" }
      vpn_gateway_interface = 1
    }
  }
}
# tftest modules=1 resources=19 inventory=bgp-route-policies.yaml
```

Policies are created on the router with their map key as name, and peers reference them by that same key. Editing a term is an in-place update, so names stay stable. Names the module does not manage (for example policies already defined on a pre-existing router) are passed through to the peer unchanged.

## Secret values

`tunnels.*.shared_secret` is an object that follows the [shape used for secrets across modules](../../adrs/modules/20261029-write-only-secrets.md):

- `value` is the secret itself
- `path` is the path to a file containing the secret, read via `file(pathexpand(path))` and relative to the root module; the file must exist at every plan
- `wo_version` switches to the provider's write-only attribute, so that the secret is never stored in state; bump the number whenever the secret changes and needs to be sent again

Only one of `value` and `path` can be set, and the secret value or file must remain present at every plan (`google_compute_vpn_tunnel` enforces `ExactlyOneOf` and `RequiredWith` on raw configuration). Without `wo_version` the secret is stored in state, and that form should only be used when this is acceptable or when upgrading an existing plain-secret tunnel in place.

When `shared_secret` is omitted (`null`), the module falls back to its internally generated `random_secret` (stored in state).

### Creating a pre-shared key

Cloud VPN accepts pre-shared keys of 1 to 128 printable ASCII characters and recommends a 24-byte random value encoded in Base64 (32 characters):

```bash
# print a 32-character secret for inline/variable use
openssl rand -base64 24

# write a secret file for shared_secret.path without a trailing newline
openssl rand -base64 24 | tr -d '\n' > vpn-psk.txt
```

Strip the trailing newline (`tr -d '\n'`) when writing secret files referenced via `path`: `file(pathexpand(path))` reads the file verbatim, so a trailing `\n` becomes part of the Google Cloud tunnel secret and will mismatch a peer router configured with the single-line string.

### Upgrading existing tunnels safely

Both `shared_secret` and `shared_secret_wo_version` on `google_compute_vpn_tunnel` are immutable (`ForceNew`). When upgrading an existing deployment from a string secret (`shared_secret = "..."`), migrate to `shared_secret = { value = "..." }` (or `{ path = "..." }`) and leave `wo_version` unset to converge with zero tunnel downtime. Adding or changing `wo_version` on an already-deployed tunnel destroys and recreates the live IPsec tunnel; use `wo_version` on new tunnels or during a planned maintenance window.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [interconnect_attachments](variables.tf#L17) | VLAN attachments used by the VPN Gateway. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L25) | Common name to identify the VPN Gateway. | <code>string</code> | ✓ |  |
| [network](variables.tf#L30) | The VPC name to which resources are associated to. | <code>string</code> | ✓ |  |
| [peer_gateway_config](variables.tf#L35) | IP addresses for the external peer gateway. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L54) | The project id. | <code>string</code> | ✓ |  |
| [region](variables.tf#L59) | GCP Region. | <code>string</code> | ✓ |  |
| [router_config](variables.tf#L64) | Cloud Router configuration for the VPN. If you want to reuse an existing router, set create to false and use name to specify the desired router. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [tunnels](variables.tf#L123) | VPN tunnel configurations. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bgp_peers](outputs.tf#L18) | BGP peer resources. |  |
| [external_gateway](outputs.tf#L25) | External VPN gateway resource. |  |
| [id](outputs.tf#L30) | Fully qualified VPN gateway id. |  |
| [random_secret](outputs.tf#L35) | Generated secret. |  |
| [route_policies](outputs.tf#L40) | BGP route policy ids, keyed by route policy key. |  |
| [router](outputs.tf#L47) | Router resource (only if auto-created). |  |
| [router_name](outputs.tf#L52) | Router name. |  |
| [self_link](outputs.tf#L57) | HA VPN gateway self link. |  |
| [tunnels](outputs.tf#L62) | VPN tunnel resources. |  |
<!-- END TFDOC -->
