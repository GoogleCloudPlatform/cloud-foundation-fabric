# Standardizing Interfaces and Features in the `net-lb` Module Family

**authors:** Antigravity (AI Assistant)
**date:** June 15, 2026

## Status

Proposed

## Context

The `net-lb` family in Cloud Foundation Fabric (CFF) consists of 8 modules covering different regional, global, and cross-region load balancer types (L4 and L7, internal and external):

| Module | LB Type | Scope | Protocol |
| :--- | :--- | :--- | :--- |
| [`net-lb-int`](file:///home/ludomagno/dev/tf-playground/cloud-foundation-fabric/modules/net-lb-int) | Internal Passthrough NLB | Regional | L4 (TCP/UDP) |
| [`net-lb-ext`](file:///home/ludomagno/dev/tf-playground/cloud-foundation-fabric/modules/net-lb-ext) | External Passthrough NLB | Regional | L4 (TCP/UDP) |
| [`net-lb-proxy-int`](file:///home/ludomagno/dev/tf-playground/cloud-foundation-fabric/modules/net-lb-proxy-int) | Internal Proxy LB | Regional | L4 (TCP) |
| [`net-lb-proxy-int-cross-region`](file:///home/ludomagno/dev/tf-playground/cloud-foundation-fabric/modules/net-lb-proxy-int-cross-region) | Internal Proxy LB | Cross-Region | L4 (TCP) |
| [`net-lb-app-int`](file:///home/ludomagno/dev/tf-playground/cloud-foundation-fabric/modules/net-lb-app-int) | Internal Application LB | Regional | L7 (HTTP/S) |
| [`net-lb-app-int-cross-region`](file:///home/ludomagno/dev/tf-playground/cloud-foundation-fabric/modules/net-lb-app-int-cross-region) | Internal Application LB | Cross-Region | L7 (HTTP/S) |
| [`net-lb-app-ext`](file:///home/ludomagno/dev/tf-playground/cloud-foundation-fabric/modules/net-lb-app-ext) | External Application LB | Global | L7 (HTTP/S) |
| [`net-lb-app-ext-regional`](file:///home/ludomagno/dev/tf-playground/cloud-foundation-fabric/modules/net-lb-app-ext-regional) | External Application LB | Regional | L7 (HTTP/S) |

These modules currently exhibit several interface inconsistencies (e.g. backend naming `group` vs `backend`, different styles for VPC config, missing context support) and, in some cases, implement invalid or unsupported features (e.g. failover and connection tracking in proxy/application load balancers) or have gaps in feature parity (e.g. URL map capabilities).

### Interface Matrix (Current State)

| Module | Forwarding Rules Style | Backends Style | Backend Key Name | Health Check Style | VPC Config Style | Context Support |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `net-lb-int` | Multi (Map) | External List | `group` | Single (Object) | Regional (Object) | Yes |
| `net-lb-ext` | Multi (Map) | External List | `group` | Single (Object) | None | No |
| `net-lb-proxy-int` | Multi (Map) | Nested (Object) | `group` | Single (Object) | Regional (Object) | Yes |
| `net-lb-proxy-int-cr` | Single (Scalar) | Nested (Object) | `group` | Single (Object) | Cross-Region (Map) | Yes |
| `net-lb-app-int` | Single (Scalar) | Nested (Map) | `group` | Multi (Map) | Regional (Object) | Yes |
| `net-lb-app-int-cr` | Single (Scalar) | Nested (Map) | `group` | Multi (Map) | Cross-Region (Map) | No |
| `net-lb-app-ext` | Multi (Map) | Nested (Map) | `backend` | Multi (Map) | None | Yes |
| `net-lb-app-ext-reg` | Single (Scalar) | Nested (Map) | `backend` | Multi (Map) | Network (String) | No |

### Resource Relationships and Interface Fit

The mapping of Terraform resources explains some necessary design differences (such as forwarding rule styles) but highlights where standardization is possible:

1.  **Passthrough NLBs (`net-lb-int`, `net-lb-ext`)**: Forwarding Rules -> Backend Service (Direct). No proxy. Multiple rules targeting one service fits a `forwarding_rules_config` map and a flat `backends` list.
2.  **Proxy LBs (Regional L4) (`net-lb-proxy-int`)**: Forwarding Rules -> Target Proxy -> Backend Service. Multiple rules point to one proxy and one backend service.
3.  **Proxy LBs (Cross-Region L4) (`net-lb-proxy-int-cross-region`)**: Global Forwarding Rules (per subnet/region) -> Global Target Proxy -> Global Backend Service. Driven by a map of subnetworks (one rule per region).
4.  **Application LBs (Regional L7) (`net-lb-app-int`, `net-lb-app-ext-regional`)**: Forwarding Rule(s) -> Target Proxy -> URL Map -> Backend Services (Multiple). URL Map routes to multiple backend services, requiring a map-based `backend_service_configs`.
5.  **Application LBs (Global/Cross-Region L7) (`net-lb-app-ext`, `net-lb-app-int-cross-region`)**: Global Forwarding Rules -> Global Target Proxy -> Global URL Map -> Global Backend Services.

## Decision

To improve consistency, maintainability, and correctness across the module family, we will implement the following changes:

### 1. Standardize Backend Key Name to `group`
We will standardize on `group` across all modules.
*   Rename `backend` to `group` in `net-lb-app-ext` and `net-lb-app-ext-regional` variables.
*   *Reasoning*: While `backend` is a generic term, `group` matches the actual Terraform provider attribute name (`group` inside the `backend` block of `google_compute_backend_service` and `google_compute_region_backend_service` for both IGs and NEGs) and is already used by 6 out of 8 modules.

### 2. Align VPC Config for Regional External ALB
*   In `net-lb-app-ext-regional`, replace the top-level `vpc` (string) variable with a `vpc_config` object containing only the `network` attribute to match the internal modules' pattern.
    ```hcl
    variable "vpc_config" {
      type = object({
        network = string
      })
    }
    ```

### 3. Remove Unsupported/Invalid Features
We will remove configuration blocks and variables for features that are not supported by the underlying GCP load balancer type, despite being supported by the shared Terraform resource type:
*   **Connection Tracking**: Only supported for Passthrough NLBs. We will remove `connection_tracking` from `net-lb-proxy-int` variables and code (which also contains a syntax typo bug `ar.backend_service_config`).
*   **Failover Configuration**: Only supported at backend service level for Passthrough NLBs. We will remove failover variables and configurations from `net-lb-proxy-int`, `net-lb-app-int`, `net-lb-app-ext`, and `net-lb-app-ext-regional`.

### 4. Implement Context Support
We will add `context` support to the three modules currently missing it:
*   `net-lb-ext`: requires `addresses`, `project_ids`, `subnets` (for IPv6).
*   `net-lb-app-int-cross-region`: requires `networks`, `subnets`, `project_ids`, `addresses`, `locations`.
*   `net-lb-app-ext-regional`: requires `networks`, `subnets`, `project_ids`, `addresses`, `locations`.

### 5. Align URL Map Features
We will align URL map capabilities across all L7 modules, as both global and regional URL map provider resources support top-level routing and header actions:
*   **Fix Bug**: Implement the missing top-level `header_action` in `net-lb-app-ext-regional`'s `urlmap.tf` (it is currently defined in variables but ignored in code).
*   **Implement Gaps**: Add top-level `default_route_action` and `header_action` to variables and resource blocks in `net-lb-app-int` and `net-lb-app-int-cross-region`.

### 6. Accept Forwarding Rules Design Differences
*   We accept that some modules use a Multi-Rule (Map) pattern (using `forwarding_rules_config`) and others use a Single-Rule (Scalar) pattern (using `address`/`ports`). This is an intentional design choice that aligns with the typical deployment patterns and usability of the specific load balancer type (e.g. regional internal ALBs usually only have one forwarding rule per target proxy, whereas passthrough NLBs benefit from multiple rules).

#### Multi-Rule Pattern (Map) Type Definition
```hcl
variable "forwarding_rules_config" {
  type = map(object({
    address       = optional(string)
    description   = optional(string)
    global_access = optional(bool, true)
    ipv6          = optional(bool, false)
    name          = optional(string)
    ports         = optional(list(string), null)
    protocol      = optional(string, "TCP")
  }))
}
```

#### Single-Rule Pattern (Scalar) Type Definition
```hcl
variable "address" {
  type    = string
  default = null
}
variable "ports" {
  type    = list(string)
  default = null
}
```

## Consequences

*   **Consistency**: Standardizing backend keys and VPC configuration makes it easier to swap or compare load balancer modules.
*   **Correctness**: Removing unsupported blocks like failover and connection tracking from proxy/app LBs prevents users from writing invalid Terraform configurations that would fail at apply time or behave unexpectedly.
*   **Feature Completeness**: Fixes a bug in `net-lb-app-ext-regional` and brings all L7 modules to parity regarding URL map routing capabilities.
*   **Portability**: Adding `context` support enables consistent symbolic resolution in landing zones (e.g. FAST) for all load balancer types.

## Reasoning

Standardizing on the provider's resource terminology (`group`) is preferred over generic terms (`backend`) to remain close to the provider's API. Removing dead code (unused failover variables) and invalid blocks ensures the modules remain lean and correct. Preserving the forwarding rules difference is a pragmatic decision that prioritizes usability over strict uniformity.

## Implementation

The standardization will be carried out across the following modules:
1.  `net-lb-ext`: Implement context support.
2.  `net-lb-proxy-int`: Remove connection tracking and failover.
3.  `net-lb-app-int`: Remove failover; implement top-level URL map routing/header actions.
4.  `net-lb-app-int-cross-region`: Implement context support; implement top-level URL map routing/header actions.
5.  `net-lb-app-ext`: Rename `backend` -> `group` in variables; remove failover variables.
6.  `net-lb-app-ext-regional`: Rename `backend` -> `group` in variables; replace `vpc` with `vpc_config`; remove failover variables; implement missing URL map `header_action`; implement context support.

## Testing

Live testing was conducted in a playground environment to verify the standardized interfaces and context resolution.

### Context Variables (Anonymized)

The following context configuration was used to resolve symbolic references (e.g. `"$project_ids:gce"`) to concrete resource IDs:

```json
{
  "context": {
    "addresses": {
      "ew1_ext": "203.0.113.10",
      "ew1_int": "192.0.2.50",
      "ew8_int": "198.51.100.2",
      "global_ext": "198.51.100.10"
    },
    "locations": {
      "ew1": "europe-west1",
      "ew8": "europe-west8"
    },
    "networks": {
      "dev": "projects/net-project-id/global/networks/vpc-name"
    },
    "project_ids": {
      "gce": "gce-project-id"
    },
    "subnets": {
      "dev/europe-west1/gce": "projects/net-project-id/regions/europe-west1/subnetworks/subnet-name-ew1",
      "dev/europe-west8/gce": "projects/net-project-id/regions/europe-west8/subnetworks/subnet-name-ew8"
    }
  }
}
```

### Test Scenarios (tfvars)

Each module was tested using specific scenarios defined in `tfvars` files. Below are the anonymized configurations used:

#### 1. `net-lb-ext`

*   **MIG Scenario (`test-mig.tfvars`)**
    ```hcl
    project_id = "$project_ids:gce"
    region     = "$locations:ew1"
    name       = "test-nlb-ext-mig"
    backends = [
      { group = "projects/gce-project-id/zones/europe-west1-b/instanceGroups/mig-name" }
    ]
    ```

*   **Context Scenario (`test-context.tfvars`)**
    ```hcl
    project_id = "$project_ids:gce"
    region     = "$locations:ew1"
    name       = "test-nlb-ext-context"
    backends = [
      { group = "projects/gce-project-id/zones/europe-west1-b/instanceGroups/mig-name" }
    ]
    forwarding_rules_config = {
      "" = {
        address = "$addresses:ew1_ext"
      }
    }
    ```

#### 2. `net-lb-proxy-int`

*   **MIG Scenario (`test-mig.tfvars`)**
    ```hcl
    project_id = "$project_ids:gce"
    region     = "$locations:ew1"
    name       = "test-ilb-l4-proxy-mig"
    vpc_config = {
      network    = "$networks:dev"
      subnetwork = "$subnets:dev/europe-west1/gce"
    }
    backend_service_config = {
      backends = [
        { group = "projects/gce-project-id/zones/europe-west1-b/instanceGroups/mig-name" }
      ]
    }
    ```

#### 3. `net-lb-proxy-int-cross-region`

*   **Multi-region MIGs (`test-cr-migs.tfvars`)**
    ```hcl
    project_id = "$project_ids:gce"
    name       = "test-ilb-l4-proxy-cr"
    vpc_config = {
      network = "$networks:dev"
      subnetworks = {
        europe-west1 = "$subnets:dev/europe-west1/gce"
        europe-west8 = "$subnets:dev/europe-west8/gce"
      }
    }
    backend_service_config = {
      backends = [
        { 
          group = "projects/gce-project-id/zones/europe-west1-b/instanceGroups/mig-name-ew1"
          max_connections = {
            per_group = 100
          }
        },
        { 
          group = "projects/gce-project-id/zones/europe-west8-b/instanceGroups/mig-name-ew8"
          max_connections = {
            per_group = 100
          }
        }
      ]
    }
    ```

#### 4. `net-lb-app-int`

*   **MIG with Actions (`test-mig-actions.tfvars`)**
    ```hcl
    project_id = "$project_ids:gce"
    region     = "$locations:ew1"
    name       = "test-ilb-l7-mig"
    global_access = true
    vpc_config = {
      network    = "$networks:dev"
      subnetwork = "$subnets:dev/europe-west1/gce"
    }
    backend_service_configs = {
      default = {
        backends = [
          { group = "projects/gce-project-id/zones/europe-west1-b/instanceGroups/mig-name" }
        ]
      }
    }
    urlmap_config = {
      default_service = "default"
      header_action = {
        response_add = {
          "x-test-header" = {
            value   = "CFF-Test-Actions"
            replace = true
          }
        }
      }
    }
    ```

#### 5. `net-lb-app-int-cross-region`

*   **Multi-region MIGs (`test-cr-migs.tfvars`)**
    ```hcl
    project_id = "$project_ids:gce"
    name       = "test-ilb-l7-cr"
    vpc_config = {
      network    = "$networks:dev"
      subnetworks = {
        europe-west1 = "$subnets:dev/europe-west1/gce"
        europe-west8 = "$subnets:dev/europe-west8/gce"
      }
    }
    backend_service_configs = {
      default = {
        backends = [
          { group = "projects/gce-project-id/zones/europe-west1-b/instanceGroups/mig-name-ew1" },
          { group = "projects/gce-project-id/zones/europe-west8-b/instanceGroups/mig-name-ew8" }
        ]
      }
    }
    ```

#### 6. `net-lb-app-ext`

*   **Cloud Run Scenario (`test-run.tfvars`)**
    ```hcl
    project_id = "$project_ids:gce"
    name       = "test-glb-l7-run"
    backend_service_configs = {
      default = {
        protocol      = "HTTP"
        health_checks = []
        backends = [
          { group = "projects/gce-project-id/regions/europe-west1/networkEndpointGroups/sneg-name" }
        ]
      }
    }
    ```

*   **MIG Scenario (`test-mig.tfvars`)**
    ```hcl
    project_id = "$project_ids:gce"
    name       = "test-glb-l7-mig"
    backend_service_configs = {
      default = {
        protocol = "HTTP"
        backends = [
          { group = "projects/gce-project-id/zones/europe-west1-b/instanceGroups/mig-name" }
        ]
      }
    }
    ```

#### 7. `net-lb-app-ext-regional`

*   **MIG Scenario (`test-mig.tfvars`)**
    ```hcl
    project_id = "$project_ids:gce"
    region     = "$locations:ew1"
    name       = "test-rlb-l7-mig"
    vpc_config = {
      network = "$networks:dev"
    }
    backend_service_configs = {
      default = {
        protocol = "HTTP"
        backends = [
          { group = "projects/gce-project-id/zones/europe-west1-b/instanceGroups/mig-name" }
        ]
      }
    }
    ```

---

## Appendix: Interface Examples

### 1. Multi-Rule Pattern with External Backends (`net-lb-int`)

```hcl
module "nlb" {
  source     = "./modules/net-lb-int"
  project_id = "my-project"
  region     = "europe-west1"
  name       = "my-nlb"

  vpc_config = {
    network    = "my-vpc"
    subnetwork = "my-subnet"
  }

  forwarding_rules_config = {
    tcp = {
      protocol = "TCP"
      ports    = ["80", "443"]
    }
    udp = {
      protocol = "UDP"
      ports    = ["53"]
    }
  }

  backends = [
    { group = "instance-group-1" },
    { group = "instance-group-2" } # Failover removed in this ADR
  ]
}
```

### 2. Single-Rule Pattern with Nested Backends (`net-lb-app-int`)

```hcl
module "ilb" {
  source     = "./modules/net-lb-app-int"
  project_id = "my-project"
  region     = "europe-west1"
  name       = "my-ilb"

  vpc_config = {
    network    = "my-vpc"
    subnetwork = "my-subnet"
  }

  protocol = "HTTP"
  ports    = ["80"]

  backend_service_configs = {
    default = {
      backends = [
        { group = "neg-1" },
        { group = "neg-2" }
      ]
    }
  }
}
```
