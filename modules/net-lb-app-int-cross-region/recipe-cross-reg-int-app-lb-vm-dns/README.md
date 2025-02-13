# Cross-region internal Application Load Balancer with VM instance group backends

This recipe shows an actual usage scenario for the [cross-region internal application load balancer](../README.md) by implementing the [example provided in the GCP documentation](https://cloud.google.com/load-balancing/docs/l7-internal/setting-up-l7-cross-reg-internal).

<p align="center">
  <img src="https://cloud.google.com/static/load-balancing/images/cross-reg-int-vm.svg" alt="Scenario diagram.">
</p>

<!-- BEGIN TOC -->
- [Prerequisites](#prerequisites)
  - [Proxy-only global subnets](#proxy-only-global-subnets)
  - [Firewall rules](#firewall-rules)
- [Variable configuration](#variable-configuration)
  - [VPC configuration options](#vpc-configuration-options)
  - [Instance configuration options](#instance-configuration-options)
  - [DNS configuration](#dns-configuration)
- [Testing](#testing)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Prerequisites

To run this recipe, you need

- an existing GCP project with the `compute` API enabled
- the `roles/compute.admin` role or equivalent (e.g. `roles/editor`) assigned on the project
- an existing VPC in the same project
- one regular subnet per region where you want to deploy the load balancer in the same VPC
- an organization policy configuration that allows creation of internal application load balancer (the default configuration is fine)
- access to the Docker Registry from the instances (e.g. via Cloud NAT)

### Proxy-only global subnets

The load balancer needs one proxy-only global subnet in each of its regions. If the subnets already exist the load balancer will consume them. If you need to create them, either do that manually or configure the module to do it for you as explained in the [Variable configuration](#variable-configuration) section below.

### Firewall rules

For the load balancer to work you need to allow ingress to the instances from the health check ranges, and from the load balancer proxy ranges. You can create firewall rules manually or configure the module to do it for you as explained in the [Variable configuration](#variable-configuration) section below.

## Variable configuration

With all the requirements in place, the only variables that are needed are those that configure the project and VPC details. Note that you need to use ids or self links in the VPC configuration not names (Shared VPC configurations are also supported).

This is a simple minimal configuration:

```tfvars
project_id = "my-project"
vpc_config = {
  network = "projects/my-project/global/networks/test"
  subnets = {
    europe-west1 = "projects/my-project/regions/europe-west1/subnetworks/default"
    europe-west8 = "projects/my-project/regions/europe-west8/subnetworks/default",
  }
}
# tftest modules=5 resources=15
```

### VPC configuration options

The VPC configuration also allows creating instances in different subnets, and auto-creation of proxy subnets and firewall rules. This is a complete configuration with all options.

```tfvars
project_id = "my-project"
vpc_config = {
  network = "projects/my-project/global/networks/test"
  subnets = {
    europe-west1 = "projects/my-project/regions/europe-west1/subnetworks/default"
    europe-west8 = "projects/my-project/regions/europe-west8/subnetworks/default",
  }
  # only specify this to use different subnets for instances
  subnets_instances = {
    europe-west1 = "projects/my-project/regions/europe-west1/subnetworks/vms"
    europe-west8 = "projects/my-project/regions/europe-west8/subnetworks/vms",
  }
  # create proxy subnets
  proxy_subnets_config = {
    europe-west1 = "172.16.193.0/24"
    europe-west8 = "172.16.192.0/24"
  }
  # create firewall rules
  firewall_config = {
    proxy_subnet_ranges = [
      "172.16.193.0/24",
      "172.16.192.0/24"
    ]
    enable_health_check = true
    enable_iap_ssh      = true
  }
}
# tftest skip
```

### Instance configuration options

The instance type and the number of zones can be configured via the `instances_config` variable:

```tfvars
project_id = "my-project"
vpc_config = {
  network = "projects/my-project/global/networks/test"
  subnets = {
    europe-west1 = "projects/my-project/regions/europe-west1/subnetworks/default"
    europe-west8 = "projects/my-project/regions/europe-west8/subnetworks/default",
  }
  instances_config = {
    # both attributes are optional
    machine_type = "e2-small"
    zones = ["b", "c"]
  }
}
# tftest modules=5 resources=15
```

### DNS configuration

The DNS zone used for the load balancer record can be configured via the `dns_config` variable:

```tfvars
project_id = "my-project"
vpc_config = {
  network = "projects/my-project/global/networks/test"
  subnets = {
    europe-west1 = "projects/my-project/regions/europe-west1/subnetworks/default"
    europe-west8 = "projects/my-project/regions/europe-west8/subnetworks/default",
  }
  dns_config = {
    # all attributes are optional
    client_networks = [
      "projects/my-project/global/networks/test",
      "projects/my-other-project/global/networks/test"
    ]
    domain          = "foo.example."
    hostname        = "lb-test"
  }
}
# tftest modules=5 resources=15
```

## Testing

To test the load balancer behaviour, you can simply disable the service on the backend instances by connecting via SSH and issuing the `sudo systemctl stop nginx` command.

If the backends are unhealthy and the necessary firewall rules are in place, check that the Docker containers have started successfully on the instances by connecting via SSH and issuing the `sudo systemctl status nginx` command.

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules |
|---|---|---|
| [instances.tf](./instances.tf) | Instance-related locals and resources. | <code>compute-vm</code> · <code>iam-service-account</code> |
| [main.tf](./main.tf) | Load balancer and VPC resources. | <code>dns</code> · <code>net-lb-app-int-cross-region</code> · <code>net-vpc</code> · <code>net-vpc-firewall</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [region_shortnames.tf](./region_shortnames.tf) | Region shortnames via locals. |  |
| [variables.tf](./variables.tf) | Module variables. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L49) | Project used to create resources. | <code>string</code> | ✓ |  |
| [vpc_config](variables.tf#L55) | VPC configuration for load balancer and instances. Subnets are keyed by region. | <code title="object&#40;&#123;&#10;  network           &#61; string&#10;  subnets           &#61; map&#40;string&#41;&#10;  subnets_instances &#61; optional&#40;map&#40;string&#41;&#41;&#10;  firewall_config &#61; optional&#40;object&#40;&#123;&#10;    proxy_subnet_ranges   &#61; list&#40;string&#41;&#10;    client_allowed_ranges &#61; optional&#40;list&#40;string&#41;&#41;&#10;    enable_health_check   &#61; optional&#40;bool, true&#41;&#10;    enable_iap_ssh        &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  proxy_subnets_config &#61; optional&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [dns_config](variables.tf#L17) | DNS configuration. | <code title="object&#40;&#123;&#10;  client_networks &#61; optional&#40;list&#40;string&#41;&#41;&#10;  domain          &#61; optional&#40;string, &#34;gce.example.&#34;&#41;&#10;  hostname        &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [instances_config](variables.tf#L28) | Configuration for instances. | <code title="object&#40;&#123;&#10;  machine_type &#61; optional&#40;string, &#34;e2-micro&#34;&#41;&#10;  zones        &#61; optional&#40;list&#40;string&#41;, &#91;&#34;b&#34;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L42) | Prefix used for resource names. | <code>string</code> |  | <code>&#34;lb-xr-00&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [instances](outputs.tf#L17) | Instances details. |  |
| [lb](outputs.tf#L34) | Load balancer details. |  |
<!-- END TFDOC -->
