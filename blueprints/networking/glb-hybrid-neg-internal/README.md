# External Application LB and multi-regional daisy-chaining through hybrid NEGs

The blueprint shows the experimental use of hybrid NEGs behind External Application Load Balancers to connect to GCP instances living in spoke VPCs and behind Network Virtual Appliances (NVAs).

<p align="center"> <img src="diagram.png" width="700"> </p>

This allows users to not configure per-destination-VM NAT rules in the NVAs.

The user traffic will enter the External Application LB, it will go across the NVAs and it will be routed to the destination VMs (or the LBs behind the VMs) in the spokes.

## What the blueprint creates

This is what the blueprint brings up, using the default module values.
The ids `primary` and `secondary` are used to identify two regions. By default, `europe-west1` and `europe-west4`.

- Projects: landing, spoke-01

- VPCs and subnets
  - landing-untrusted: primary - 192.168.1.0/24 and secondary - 192.168.2.0/24
  - landing-trusted: primary - 192.168.11.0/24 and secondary - 192.168.22.0/24
  - spoke-01: primary - 192.168.101.0/24 and secondary - 192.168.102.0/24

- Cloud NAT
  - landing-untrusted (both for primary and secondary)
  - in spoke-01 (both for primary and secondary) - this is just for test purposes, so you VMs can automatically install nginx, even if NVAs are still not ready

- VMs
  - NVAs in MIGs in the landing project, both in primary and secondary, with NICs in the untrusted and in the trusted VPCs
  - Test VMs, in spoke-01, both in primary and secondary. Optionally, deployed in MIGs

- Hybrid NEGs in the untrusted VPC, both in primary and secondary, either pointing to the test VMs in the spoke or -optionally- to LBs in the spokes (if test VMs are deployed as MIGs)

- Internal Network Load balancers (L4 LBs)
  - in the untrusted VPC pointing to NVA MIGs, both in primary and secondary. Their VIPs are used by custom routes in the untrusted VPC, so that all traffic that arrives in the untrusted VPC destined for the test VMs in the spoke is sent through the NVAs
  - optionally, in the spokes. They are created if the user decides to deploy the test VMs as MIGs

- External Global Load balancer (GLB) in the untrusted VPC, using the hybrid NEGs as its backends

## Health Checks

Google Cloud sends [health checks](https://cloud.google.com/load-balancing/docs/health-checks) using [specific IP ranges](https://cloud.google.com/load-balancing/docs/health-checks#fw-netlb). Each VPC uses [implicit routes](https://cloud.google.com/vpc/docs/routes#special_return_paths) to send the health check replies back to Google.

At the moment of writing, when Google Cloud sends out [health checks](https://cloud.google.com/load-balancing/docs/health-checks) against backend services, it expects replies to come back from the same VPC where they have been sent out to.

Given the GLB lives in the untrusted VPC, its backend service health checks are sent out to that VPC, and so the replies are expected from it. Anyway, the destinations of the health checks are the test VMs in the spokes.

The blueprint configures some custom routes in the untrusted VPC and routing/NAT rules in the NVAs, so that health checks reach the test VMs through the NVAs, and replies come back through the NVAs in the untrusted VPC. Without these configurations health checks will fail and backend services won't be reachable.

Specifically:

- we create two custom routes in the untrusted VPC (one per region) so that traffic for the spoke subnets is sent to the VIP of the L4 LBs in front of the NVAs

- we configure the NVAs so they know how to route traffic to the spokes via the trusted VPC gateway

- we configure the NVAs to s-NAT (specifically, masquerade) health checks traffic destined to the test VMs

## Change the ilb_create variable

Through the `ilb_create` variable you can decide whether test VMs in the spoke will be deployed as MIGs with LBs in front. This will also configure NEGs, so they point to the LB VIPs, instead of the VM IPs.

At the moment, every time a user changes the configuration of a NEG, the NEG is recreated. When this happens, the provider doesn't check if it is used by other resources, such as GLB backend services. Until this doesn't get fixed, every time you'll need to change the NEG configuration (i.e. when changing the variable `ilb_create`) you'll have to workaround it. Here is how:

- Destroy the existing backend service: `terraform destroy -target 'module.hybrid-glb.google_compute_backend_service.default["default"]'`

- Change the variable `ilb_create`

- run `terraform apply`
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [prefix](variables.tf#L36) | Prefix used for resource names. | <code>string</code> | ✓ |  |
| [ilb_create](variables.tf#L17) | Whether we should create an ILB L4 in front of the test VMs in the spoke. | <code>string</code> |  | <code>&#34;false&#34;</code> |
| [ip_config](variables.tf#L23) | The subnet IP configurations. | <code title="object&#40;&#123;&#10;  spoke_primary       &#61; optional&#40;string, &#34;192.168.101.0&#47;24&#34;&#41;&#10;  spoke_secondary     &#61; optional&#40;string, &#34;192.168.102.0&#47;24&#34;&#41;&#10;  trusted_primary     &#61; optional&#40;string, &#34;192.168.11.0&#47;24&#34;&#41;&#10;  trusted_secondary   &#61; optional&#40;string, &#34;192.168.22.0&#47;24&#34;&#41;&#10;  untrusted_primary   &#61; optional&#40;string, &#34;192.168.1.0&#47;24&#34;&#41;&#10;  untrusted_secondary &#61; optional&#40;string, &#34;192.168.2.0&#47;24&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [project_names](variables.tf#L45) | The project names. | <code title="object&#40;&#123;&#10;  landing  &#61; string&#10;  spoke_01 &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  landing  &#61; &#34;landing&#34;&#10;  spoke_01 &#61; &#34;spoke-01&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [projects_create](variables.tf#L57) | Parameters for the creation of the new project. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [regions](variables.tf#L66) | Region definitions. | <code title="object&#40;&#123;&#10;  primary   &#61; string&#10;  secondary &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  primary   &#61; &#34;europe-west1&#34;&#10;  secondary &#61; &#34;europe-west4&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [glb_ip_address](outputs.tf#L17) | Load balancer IP address. |  |

<!-- END TFDOC -->
## Test

```hcl
module "test" {
  source = "./fabric/blueprints/networking/glb-hybrid-neg-internal"
  prefix = "prefix"
  projects_create = {
    billing_account_id = "123456-123456-123456"
    parent             = "folders/123456789"
  }
}

# tftest modules=21 resources=80
```
