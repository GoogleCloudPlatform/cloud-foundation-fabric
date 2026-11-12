# Cloud HA VPN Module

This module makes it easy to deploy either GCP-to-GCP or GCP-to-On-prem [Cloud HA VPN](https://cloud.google.com/network-connectivity/docs/vpn/concepts/overview#ha-vpn).

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [GCP to GCP](#gcp-to-gcp)
  - [GCP to on-prem](#gcp-to-on-prem)
  - [GCP to on-prem with custom ciphers](#gcp-to-on-prem-with-custom-ciphers)
  - [IPv6 (dual-stack)](#ipv6-dual-stack)
  - [BGP Route Policies](#bgp-route-policies)
- [Secret values](#secret-values)
  - [Creating a pre-shared key](#creating-a-pre-shared-key)
  - [Upgrading existing tunnels safely](#upgrading-existing-tunnels-safely)
- [Recipes](#recipes)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Examples

### GCP to GCP

```hcl
module "vpn-1" {
  source     = "./fabric/modules/net-vpn-ha"
  project_id = var.project_id
  region     = "europe-west4"
  network    = var.vpc1.self_link
  name       = "net1-to-net-2"
  peer_gateways = {
    default = { gcp = module.vpn-2.self_link }
  }
  router_config = {
    asn = 64514
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        "10.0.0.0/8" = "default"
      }
    }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.1.2/30"
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_session_range     = "169.254.2.2/30"
      vpn_gateway_interface = 1
    }
  }
}

module "vpn-2" {
  source        = "./fabric/modules/net-vpn-ha"
  project_id    = var.project_id
  region        = "europe-west4"
  network       = var.vpc2.self_link
  name          = "net2-to-net1"
  router_config = { asn = 64513 }
  peer_gateways = {
    default = { gcp = module.vpn-1.self_link }
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.1.1/30"
      shared_secret         = { value = module.vpn-1.shared_secrets["remote-0"] }
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_session_range     = "169.254.2.1/30"
      shared_secret         = { value = module.vpn-1.shared_secrets["remote-1"] }
      vpn_gateway_interface = 1
    }
  }
}
# tftest modules=2 resources=22 inventory=gcp-to-gcp.yaml
```

Note: When using the `for_each` meta-argument you might experience a Cycle Error due to the multiple `net-vpn-ha` modules referencing each other. To fix this you can create the [google_compute_ha_vpn_gateway](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ha_vpn_gateway) resources separately and reference them in the `net-vpn-ha` module via the `vpn_gateway` and `peer_gcp_gateway` variables.

### GCP to on-prem

```hcl
module "vpn_ha" {
  source     = "./fabric/modules/net-vpn-ha"
  project_id = var.project_id
  region     = var.region
  network    = var.vpc.self_link
  name       = "mynet-to-onprem"
  peer_gateways = {
    default = {
      external = {
        redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
        interfaces      = ["8.8.8.8"] # on-prem router ip address
      }
    }
  }
  router_config = { asn = 64514 }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
        # Custom learned routes are optional
        custom_learned_ip_ranges = {
          ip_ranges = {
            "onprem-range" = "10.128.0.0/16"
          }
        }
        # MD5 Authentication is optional
        md5_authentication_key = {
          name = "foo"
          key  = "bar"
        }
      }
      bgp_session_range               = "169.254.1.2/30"
      peer_external_gateway_interface = 0
      shared_secret = {
        value      = "mySecret"
        wo_version = 1
      }
      vpn_gateway_interface = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
        # Custom learned routes are optional
        custom_learned_ip_ranges = {
          ip_ranges = {
            "onprem-range" = "10.128.0.0/16"
          }
        }
        # MD5 Authentication is optional
        md5_authentication_key = {
          name = "foo"
          key  = "bar"
        }
      }
      bgp_session_range               = "169.254.2.2/30"
      peer_external_gateway_interface = 0
      shared_secret = {
        value      = "mySecret"
        wo_version = 1
      }
      vpn_gateway_interface = 1
    }
  }
}
# tftest modules=1 resources=12 inventory=gcp-to-onprem.yaml
```

### GCP to on-prem with custom ciphers

```hcl
module "vpn_ha" {
  source     = "./fabric/modules/net-vpn-ha"
  project_id = var.project_id
  region     = var.region
  network    = var.vpc.self_link
  name       = "mynet-to-onprem"
  peer_gateways = {
    default = {
      external = {
        redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
        interfaces      = ["8.8.8.8"] # on-prem router ip address
      }
    }
  }
  router_config = { asn = 64514 }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
        # Custom learned routes are optional
        custom_learned_ip_ranges = {
          ip_ranges = {
            "onprem-range" = "10.128.0.0/16"
          }
        }
        # MD5 Authentication is optional
        md5_authentication_key = {
          name = "foo"
          key  = "bar"
        }
      }
      bgp_session_range = "169.254.1.2/30"
      cipher_suite = {
        phase1 = {
          dh         = ["Group-14"]
          encryption = ["AES-CBC-256"]
          integrity  = ["HMAC-SHA2-256-128"]
          prf        = ["PRF-HMAC-SHA2-256"]
        }
        phase2 = {
          encryption = ["AES-CBC-128"]
          integrity  = ["HMAC-SHA2-256-128"]
          pfs        = ["Group-14"]
        }
      }
      peer_external_gateway_interface = 0
      shared_secret                   = { value = "mySecret" }
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
        # Custom learned routes are optional
        custom_learned_ip_ranges = {
          ip_ranges = {
            "onprem-range" = "10.128.0.0/16"
          }
        }
        # MD5 Authentication is optional
        md5_authentication_key = {
          name = "foo"
          key  = "bar"
        }
      }
      bgp_session_range = "169.254.2.2/30"
      cipher_suite = {
        phase1 = {
          dh         = ["Group-14"]
          encryption = ["AES-CBC-256"]
          integrity  = ["HMAC-SHA2-256-128"]
          prf        = ["PRF-HMAC-SHA2-256"]
        }
        phase2 = {
          encryption = ["AES-CBC-128"]
          integrity  = ["HMAC-SHA2-256-128"]
          pfs        = ["Group-14"]
        }
      }
      peer_external_gateway_interface = 0
      shared_secret                   = { value = "mySecret" }
      vpn_gateway_interface           = 1
    }
  }
}
# tftest modules=1 resources=12 inventory=gcp-to-onprem-custom-ciphers.yaml
```

### IPv6 (dual-stack)

You can optionally set your HA VPN gateway (and BGP sessions) to carry both IPv4 and IPv6 traffic. IPv6 only is not supported.

```hcl
module "vpn_ha" {
  source     = "./fabric/modules/net-vpn-ha"
  project_id = var.project_id
  region     = var.region
  name       = "mynet-to-onprem"
  network    = var.vpc.self_link
  peer_gateways = {
    default = {
      external = {
        redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
        interfaces      = ["8.8.8.8"] # on-prem router ip address
      }
    }
  }
  router_config = { asn = 64514 }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
        ipv6    = {}
      }
      bgp_session_range               = "169.254.1.2/30"
      peer_external_gateway_interface = 0
      shared_secret                   = { value = "mySecret" }
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
        ipv6 = {
          nexthop_address      = "2600:2d00:0:2::1"
          peer_nexthop_address = "2600:2d00:0:3::1"
        }
      }
      bgp_session_range               = "169.254.2.2/30"
      peer_external_gateway_interface = 0
      shared_secret                   = { value = "mySecret" }
      vpn_gateway_interface           = 1
    }
  }
  vpn_gateway_create = {
    ipv6 = true
  }
}
# tftest modules=1 resources=12 inventory=ipv6.yaml
```

### BGP Route Policies

```hcl
module "vpn_ha" {
  source     = "./fabric/modules/net-vpn-ha"
  project_id = var.project_id
  region     = var.region
  network    = var.vpc.self_link
  name       = "mynet-to-onprem"
  peer_gateways = {
    default = {
      external = {
        redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
        interfaces      = ["8.8.8.8"]
      }
    }
  }
  router_config = {
    asn = 64514
    custom_advertise = {
      all_subnets = true
      ip_ranges = {
        "10.10.0.0/24" = "default"
      }
    }
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
              expression = "destination == '10.10.0.0/24'"
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
        address         = "169.254.1.1"
        asn             = 64513
        import_policies = ["import-rfc1918", "import-drop-all"]
        export_policies = ["export-policy"]
      }
      bgp_session_range               = "169.254.1.2/30"
      peer_external_gateway_interface = 0
      shared_secret                   = { value = "mySecret" }
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address         = "169.254.2.1"
        asn             = 64513
        import_policies = ["import-rfc1918", "import-drop-all"]
        export_policies = ["export-policy"]
      }
      bgp_session_range               = "169.254.2.2/30"
      peer_external_gateway_interface = 0
      shared_secret                   = { value = "mySecret" }
      vpn_gateway_interface           = 1
    }
  }
}
# tftest modules=1 resources=15 inventory=bgp-route-policies.yaml
```

Policies are created on the router with their map key as name, and peers reference them by that same key. Editing a term is an in-place update, so names stay stable. Names the module does not manage (for example policies already defined on a pre-existing router) are passed through to the peer unchanged.

You can optionally avoid to specify MD5 keys and the module will automatically generate them for you.

## Secret values

`tunnels.*.shared_secret` is an object that follows the [shape used for secrets across modules](../../adrs/modules/20261029-write-only-secrets.md):

- `value` is the secret itself
- `path` is the path to a file containing the secret, read via `file(pathexpand(path))` and relative to the root module; the file must exist at every plan
- `wo_version` switches to the provider's write-only attribute, so that the secret is never stored in state; bump the number whenever the secret changes and needs to be sent again

Only one of `value` and `path` can be set, and the secret value or file must remain present at every plan (`google_compute_vpn_tunnel` enforces `ExactlyOneOf` and `RequiredWith` on raw configuration). Without `wo_version` the secret is stored in state, and that form should only be used when this is acceptable or when upgrading an existing plain-secret tunnel in place.

When `shared_secret` is omitted (`null`), the module falls back to its internally generated `random_secret` (stored in state). When `wo_version` is set on a tunnel, its entry in the `shared_secrets` output is `null` so the secret is not persisted in state.

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
## Recipes

- [HA VPN connections between Google Cloud and AWS](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/modules/net-vpn-ha/recipe-vpn-aws-gcp)

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L31) | VPN Gateway name (if an existing VPN Gateway is not used), and prefix used for dependent resources. | <code>string</code> | ✓ |  |
| [network](variables.tf#L36) | VPC used for the gateway and routes. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L62) | Project where resources will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L67) | Region used for resources. | <code>string</code> | ✓ |  |
| [router_config](variables.tf#L72) | Cloud Router configuration for the VPN. If you want to reuse an existing router, set create to false and use name to specify the desired router. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [peer_gateways](variables.tf#L41) | Configuration of the (external or GCP) peer gateway. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tunnels](variables.tf#L132) | VPN tunnel configurations. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vpn_gateway](variables.tf#L200) | HA VPN Gateway Self Link for using an existing HA VPN Gateway. Ignored if `vpn_gateway_create` is set to `true`. | <code>string</code> |  | <code>null</code> |
| [vpn_gateway_create](variables.tf#L206) | Create HA VPN Gateway. Set to null to avoid creation. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [bgp_peers](outputs.tf#L18) | BGP peer resources. |  |
| [external_gateway](outputs.tf#L25) | External VPN gateway resource. |  |
| [gateway](outputs.tf#L30) | VPN gateway resource (only if auto-created). |  |
| [id](outputs.tf#L35) | Fully qualified VPN gateway id. |  |
| [md5_keys](outputs.tf#L42) | BGP tunnels MD5 keys. | ✓ |
| [name](outputs.tf#L54) | VPN gateway name (only if auto-created). |  |
| [random_secret](outputs.tf#L59) | Generated secret. | ✓ |
| [route_policies](outputs.tf#L65) | BGP route policy ids, keyed by route policy key. |  |
| [router](outputs.tf#L72) | Router resource (only if auto-created). |  |
| [router_name](outputs.tf#L77) | Router name. |  |
| [self_link](outputs.tf#L82) | HA VPN gateway self link. |  |
| [shared_secrets](outputs.tf#L87) | IPSEC tunnels shared secrets. | ✓ |
| [tunnel_names](outputs.tf#L99) | VPN tunnel names. |  |
| [tunnel_self_links](outputs.tf#L107) | VPN tunnel self links. |  |
| [tunnels](outputs.tf#L115) | VPN tunnel resources. |  |
<!-- END TFDOC -->
