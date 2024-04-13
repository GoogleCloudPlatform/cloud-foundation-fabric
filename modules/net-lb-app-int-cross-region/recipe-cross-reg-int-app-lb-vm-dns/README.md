# Cross-region internal Application Load Balancer with VM instance group backends

This recipe shows an actual usage scenario for the [cross-region internal application load balancer](../README.md) by implementing the [example provided in the GCP documentation](https://cloud.google.com/load-balancing/docs/l7-internal/setting-up-l7-cross-reg-internal).

<p align="center">
  <img src="https://cloud.google.com/static/load-balancing/images/cross-reg-int-vm.svg" alt="Scenario diagram.">
</p>

## Prerequisites

### Proxy-only global subnets

The load balancer needs one proxy-only global subnet in each of its regions. If you are using the [`net-vpc`](../../net-vpc/) module with the subnet factory enabled, this is an example on how to create one of the subnets.

```yaml
# data/subnets/proxy-global-ew1.yaml
region: europe-west1
ip_cidr_range: 172.16.192.0/24
proxy_only: true
global: true
description: Terraform-managed proxy-only subnet for Regional HTTPS or Internal HTTPS LB.
```

### Firewall rules

## Variable configuration

## Testing
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L49) | Project used to create resources. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L69) | VPC configuration for load balancer and instances. Subnets are keyed by region. | <code title="object&#40;&#123;&#10;  network           &#61; string&#10;  subnets           &#61; map&#40;string&#41;&#10;  subnets_instances &#61; optional&#40;map&#40;string&#41;&#41;&#10;  firewall_config &#61; optional&#40;object&#40;&#123;&#10;    proxy_subnet_ranges   &#61; list&#40;string&#41;&#10;    client_allowed_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;    enable_health_check   &#61; optional&#40;bool, true&#41;&#10;    enable_iap_ssh        &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [dns_config](variables.tf#L17) | DNS configuration. | <code title="object&#40;&#123;&#10;  client_networks &#61; optional&#40;list&#40;string&#41;&#41;&#10;  domain          &#61; optional&#40;string, &#34;gce.example.&#34;&#41;&#10;  hostname        &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [instances_config](variables.tf#L28) | Configuration for instances. | <code title="object&#40;&#123;&#10;  machine_type &#61; optional&#40;string, &#34;e2-micro&#34;&#41;&#10;  zones        &#61; optional&#40;list&#40;string&#41;, &#91;&#34;b&#34;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L42) | Prefix used for or in resource names. | <code>string</code> |  | <code>&#34;lb-xr-00&#34;</code> |
| [regions](variables.tf#L55) | Regions used for the compute resources, use shortnames as keys. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  ew1 &#61; &#34;europe-west1&#34;&#10;  ew3 &#61; &#34;europe-west3&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
<!-- END TFDOC -->
