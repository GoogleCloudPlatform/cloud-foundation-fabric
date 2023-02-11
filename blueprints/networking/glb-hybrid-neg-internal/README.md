# XGLB and multi-reginoal daisy-chaining through hybrid NEGs

The blueprint shows the experimental use of hybrid NEGs behind eXternal Global Load Balancers (XGLBs) to connect to GCP instances living in spoke VPCs and behind Network Virtual Appliances (NVAs).

<p align="center"> <img src="diagram.png" width="700"> </p>

This allows users to not configure per-destination-VM NAT rules in the NVAs.

The user traffic will enter the XGLB, it will go across the NVAs and it will be routed to the destination VMs (or the ILBs behind the VMs) in the spokes.

## What the blueprint creates

This is what the blueprint brings up, using the default module values.
The ids `r1` and `r2` are used to identify two regions. By default, `europe-west1` and `europe-west2`.

- Projects: landing, spoke-01

- VPCs and subnets
	+ landing-untrusted: r1 - 192.168.1.0/24 and r2 - 192.168.2.0/24
	+ landing-trusted: r1 - 192.168.11.0/24 and r2 - 192.168.22.0/24
	+ spoke-01: r1 - 192.168.101.0/24 and r2 - 192.168.102.0/24

- Cloud NAT
	+ landing-untrusted (both for r1 and r2)
	+ in spoke-01 (both for r1 and r2) - this is just for test purposes, so you VMs can automatically install nginx, even if NVAs are still not ready

- VMs
	+ NVAs in MIGs in the landing project, both in r1 and r2, with NICs in the untrusted and in the trusted VPCs
	+ Test VMs, in spoke-01, both in r1 and r2. Optionally, deployed in MIGs

- Hybrid NEGs in the untrusted VPC, both in r1 and r2, either pointing to the test VMs in the spoke or -optionally- to ILBs in the spokes (if test VMs are deployed as MIGs)

- Internal Load balancers (L4 ILBs)
	+ in the untrusted VPC, pointing to NVA MIGs, both in r1 and r2. Their VIPs are used by custom routes in the untrusted VPC, so that all traffic that arrives in the untrusted VPC destined for the test VMs in the spoke is sent through the NVAs
	+ optionally, in the spokes. They are created if the user decides to deploy the test VMs as MIGs

- External Global Load balancer (XGLB) in the untrusted VPC, using the hybrid NEGs as its backends

## Health Checks

Google Cloud sends [health checks](https://cloud.google.com/load-balancing/docs/health-checks) using [specific IP ranges](https://cloud.google.com/load-balancing/docs/health-checks#fw-netlb). Each VPC uses [implicit routes](https://cloud.google.com/vpc/docs/routes#special_return_paths) to send the health check replies back to Google.

At the moment of writing, when Google Cloud sends out [health checks](https://cloud.google.com/load-balancing/docs/health-checks) against backend services, it expects replies to come back from the same VPC where they have been sent out to.

Given the XGLB lives in the untrusted VPC, its backend service health checks are sent out to that VPC, and so the replies are expected from it. Anyway, the destinations of the health checks are the test VMs in the spokes.

The blueprint configures some custom routes in the untrusted VPC and routing/NAT rules in the NVAs, so that health checks reach the test VMs through the NVAs, and replies come back through the NVAs in the untrusted VPC. Without these configurations health checks will fail and backend services won't be reachable.

Specifically:

- we create two custom routes in the untrusted VPC (one per region) so that traffic for the spoke subnets is sent to the VIP of the L4 ILBs in front of the NVAs

- we configure the NVAs so they know how to route traffic to the spokes via the trusted VPC gateway

- we configure the NVAs to s-NAT (specifically, masquerade) health checks traffic destined to the test VMs

## Change the test_vms_behind_ilb variable

Through the `test_vms_behind_ilb` variable you can decide whether test VMs in the spoke will be deployed as MIGs with ILBs in front. This will also configure NEGs, so they point to the ILB VIPs, instead of the VM IPs.

At the moment, every time a user changes the configuration of a NEG, the NEG is recreated. When this happens, the provider doesn't check if it is used by other resources, such as XGLB backend services. Until this doesn't get fixed, every time you'll need to change the NEG configuration (i.e. when changing the variable `test_vms_behind_ilb`) you'll have to workaround it. Here is how:

- Destroy the existing backend service: `terraform destroy -target 'module.hybrid-glb.google_compute_backend_service.default["default"]'`

- Change the variable `test_vms_behind_ilb`

- run `terraform apply`
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [prefix](variables.tf#L17) | Prefix used for resource names. | <code>string</code> | ✓ |  |
| [projects_create](variables.tf#L26) | Parameters for the creation of the new project. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  parent             &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [region_configs](variables.tf#L35) | The primary and secondary region parameters. | <code title="object&#40;&#123;&#10;  r1 &#61; object&#40;&#123;&#10;    region_name &#61; string&#10;    zone        &#61; string&#10;  &#125;&#41;&#10;  r2 &#61; object&#40;&#123;&#10;    region_name &#61; string&#10;    zone        &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  r1 &#61; &#123;&#10;    region_name &#61; &#34;europe-west1&#34;&#10;    zone        &#61; &#34;europe-west1-b&#34;&#10;  &#125;&#10;  r2 &#61; &#123;&#10;    region_name &#61; &#34;europe-west2&#34;&#10;    zone        &#61; &#34;europe-west2-b&#34;&#10;  &#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [test_vms_behind_ilb](variables.tf#L59) | Whether there should be an ILB L4 in front of the test VMs in the spoke. | <code>string</code> |  | <code>&#34;false&#34;</code> |
| [vpc_landing_trusted_config](variables.tf#L77) | The configuration of the landing trusted VPC | <code title="object&#40;&#123;&#10;  r1_cidr &#61; string&#10;  r2_cidr &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  r1_cidr &#61; &#34;192.168.11.0&#47;24&#34;,&#10;  r2_cidr &#61; &#34;192.168.22.0&#47;24&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [vpc_landing_untrusted_config](variables.tf#L65) | The configuration of the landing untrusted VPC | <code title="object&#40;&#123;&#10;  r1_cidr &#61; string&#10;  r2_cidr &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  r1_cidr &#61; &#34;192.168.1.0&#47;24&#34;,&#10;  r2_cidr &#61; &#34;192.168.2.0&#47;24&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [vpc_spoke_config](variables.tf#L89) | The configuration of the spoke-01 VPC | <code title="object&#40;&#123;&#10;  r1_cidr &#61; string&#10;  r2_cidr &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  r1_cidr &#61; &#34;192.168.101.0&#47;24&#34;,&#10;  r2_cidr &#61; &#34;192.168.102.0&#47;24&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |

<!-- END TFDOC -->
