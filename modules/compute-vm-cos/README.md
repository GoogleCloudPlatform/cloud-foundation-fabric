# Container Optimized OS module

This module allows creating instances (or an instance template) runnning a containerized application  using CoreDNS. A service account will be created if none is set.

## Example

```hcl
module "onprem-dns" {
  source     = "./modules/compute-vm-cos-coredns"
  project_id = var.project_id
  region     = var.region
  zone       = var.zone
  name       = "coredns"
  network_interfaces = [{
    network    = var.vpc_self_link
    subnetwork = var.subnet_self_link
    nat        = false,
    addresses  = null
  }]
  coredns_corefile = <<END
  example.com {
    hosts /etc/coredns/hosts
    log
    errors
  }
  . {
    forward . /etc/resolv.conf
    log
    errors
  }
  END
  files = {
    "/etc/coredns/hosts" = {
      content    = "127.0.0.1 localhost.example.com"
      attributes = null
    }
  }
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| image | Container image. | <code title="">string</code> | ✓ |  |
| name | Instances base name. | <code title="">string</code> | ✓ |  |
| network_interfaces | Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed. | <code title="list&#40;object&#40;&#123;&#10;nat        &#61; bool&#10;network    &#61; string&#10;subnetwork &#61; string&#10;addresses &#61; object&#40;&#123;&#10;internal &#61; list&#40;string&#41;&#10;external &#61; list&#40;string&#41;&#10;&#125;&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> | ✓ |  |
| project_id | Project id. | <code title="">string</code> | ✓ |  |
| region | Compute region. | <code title="">string</code> | ✓ |  |
| zone | Compute zone. | <code title="">string</code> | ✓ |  |
| *boot_disk* | Boot disk properties. | <code title="object&#40;&#123;&#10;image &#61; string&#10;size  &#61; number&#10;type &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;image &#61; &#34;projects&#47;cos-cloud&#47;global&#47;images&#47;family&#47;cos-stable&#34;&#10;type &#61; &#34;pd-ssd&#34;&#10;size  &#61; 10&#10;&#125;">...</code> |
| *cos_config* | Configure COS logging and monitoring. | <code title="object&#40;&#123;&#10;logging    &#61; bool&#10;monitoring &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;logging    &#61; false&#10;monitoring &#61; true&#10;&#125;">...</code> |
| *exposed_ports* | Ports to expose in the host | <code title="object&#40;&#123;&#10;tcp &#61; list&#40;number&#41;&#10;udp &#61; list&#40;number&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;tcp &#61; &#91;&#93;&#10;udp &#61; &#91;&#93;&#10;&#125;">...</code> |
| *extra_args* | Extra arguments to pass to the container | <code title="">string</code> |  | <code title=""></code> |
| *files* | Map of files to create on the instances, path as key. Attributes default to 'root' and '0644', set to null if not needed. | <code title="map&#40;object&#40;&#123;&#10;content &#61; string&#10;attributes &#61; object&#40;&#123;&#10;owner       &#61; string&#10;permissions &#61; string&#10;&#125;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *hostname* | Instance FQDN name. | <code title="">string</code> |  | <code title="">null</code> |
| *instance_count* | Number of instances to create (only for non-template usage). | <code title="">number</code> |  | <code title="">1</code> |
| *instance_type* | Instance type. | <code title="">string</code> |  | <code title="">f1-micro</code> |
| *labels* | Instance labels. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *log_driver* | Container log driver (local, gcplogs, etc.). | <code title="">string</code> |  | <code title="">gcplogs</code> |
| *metadata* | Instance metadata. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *min_cpu_platform* | Minimum CPU platform. | <code title="">string</code> |  | <code title="">null</code> |
| *options* | Instance options. | <code title="object&#40;&#123;&#10;allow_stopping_for_update &#61; bool&#10;can_ip_forward            &#61; bool&#10;deletion_protection       &#61; bool&#10;preemptible               &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;allow_stopping_for_update &#61; true&#10;can_ip_forward            &#61; false&#10;deletion_protection       &#61; false&#10;preemptible               &#61; false&#10;&#125;">...</code> |
| *post_runcmds* | Extra commands to run (in the host) after starting the container. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *pre_runcmds* | Extra commands to run (in the host) before starting the container. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *service_account* | Service account email (leave empty to auto-create). | <code title="">string</code> |  | <code title=""></code> |
| *tags* | Instance tags. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["dns", "ssh"]</code> |
| *use_instance_template* | Create instance template instead of instances. | <code title="">bool</code> |  | <code title="">false</code> |
| *volumes* | Map of volumes to mount in the container, key is the host path, value is the mount location inside the container | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| external_ips | Instance main interface external IP addresses. |  |
| instances | Instance resources. |  |
| internal_ips | Instance main interface internal IP addresses. |  |
| names | Instance names. |  |
| self_links | Instance self links. |  |
| template | Template resource. |  |
| template_name | Template name. |  |
<!-- END TFDOC -->
