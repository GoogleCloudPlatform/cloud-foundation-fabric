# Container Optimized OS module

This module allows creating instances (or an instance template) runnning a containerized application using COS. A service account will be created if none is set.

This module can be used with a custom cloud-config template or with one of the provided preset configurations.

## Examples

### CoreDNS preset

This preset creates CoreDNS instances. Use `preset:coredns.yaml` as the value for `cloud_config.template_path` and you must specify the following variables:

| name      | description                                                                                                                         | type                         | required |
|-----------|-------------------------------------------------------------------------------------------------------------------------------------|:----------------------------:|:--------:|
| corefile  | CoreDNS Corefile content, use `"default"` to use sample configuration.                                                              | <code title="">string</code> | ✓        |
| logdriver | CoreDNS container log driver (local, gcplogs, etc.).                                                                                | <code title="">string</code> | ✓        |
| files     | Map of files to create on the instances, path as key, value must be an `object({content=string, owner=string, permissions=string})` | <code title="">object</code> | ✓        |

```hcl
module "coredns" {
  source     = "./modules/compute-vm-cos"
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

  cloud_config = {
    template_path = "preset:coredns.yaml"
    variables = {
      corefile   = "default"
      log_driver = "gcplogs"
      files      = {}
    }
  }
}
```

### Generic preset

This preset creates a COS instance and runs the specfied container image. Use `preset:generic.yaml` as the value for `cloud_config.template_path` and you must specify the following variables:

| name          | description                                                                                                                         | type                                                                 | required |
|---------------|-------------------------------------------------------------------------------------------------------------------------------------|:--------------------------------------------------------------------:|:--------:|
| image         | Container image to run                                                                                                              | <code title="">string</code>                                         | ✓        |
| extra_args    | Extra arguments to pass to the container                                                                                            | <code title="">string</code>                                         | ✓        |
| logdriver     | Container log driver (local, gcplogs, etc.).                                                                                        | <code title="">string</code>                                         | ✓        |
| files         | Map of files to create on the instances, path as key, value must be an `object({content=string, owner=string, permissions=string})` | <code title="">object</code>                                         | ✓         |
| volumes       | Map volumes to mount in the container. Key is the host path and value is the container path                                         | <code title="">map(string)</code>                                    |          |
| pre_runcmds   | List of commands to run before starting the container                                                                               | <code title="">list(string)</code>                                   |          |
| post_runcmds  | List of commands to run after starting the container                                                                                | <code title="">list(string)</code>                                   |          |
| exposed_ports | List of ports to expose in the host.                                                                                                | <code title="">object({tcp = list(string), udp=list(string)})</code> |          |


```hcl
module "nginx" {
  source     = "./modules/compute-vm-cos"
  project_id = var.project_id
  region     = var.region
  zone       = var.zone
  name       = "nginx"
  network_interfaces = [{
    network    = var.vpc_self_link
    subnetwork = var.subnet_self_link
    nat        = false,
    addresses  = null
  }]
  cloud_config = {
    template_path = "preset:generic.yaml"
    variables = {
      image = "nginx:1.17"
      files = {
        "/etc/nginx/htdocs/index.html" : {
          content = "hello world"
        }
      }
      exposed_ports = {
        tcp = [80]
      }
      volumes = {
        "/etc/nginx/htdocs" : "/usr/share/nginx/html"
      }
    }
  }
}
```

### User-defined configuration

```hcl
module "nginx" {
  source     = "./modules/compute-vm-cos"
  project_id = var.project_id
  region     = var.region
  zone       = var.zone
  name       = "nginx"
  network_interfaces = [{
    network    = var.vpc_self_link
    subnetwork = var.subnet_self_link
    nat        = false,
    addresses  = null
  }]
  cloud_config = {
    template_path = "${module.path}/mytemplate.yaml"
    variables = {
      var1 = "value1"
      var2 = "value2"
    }
  }
}
```


<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| cloud_config | Configuration for rendering the cloud-config string for the instance. Must be a map with two keys: template_path and variables | <code title=""></code> | ✓ |  |
| name | Instances base name. | <code title="">string</code> | ✓ |  |
| network_interfaces | Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed. | <code title="list&#40;object&#40;&#123;&#10;nat        &#61; bool&#10;network    &#61; string&#10;subnetwork &#61; string&#10;addresses &#61; object&#40;&#123;&#10;internal &#61; list&#40;string&#41;&#10;external &#61; list&#40;string&#41;&#10;&#125;&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> | ✓ |  |
| project_id | Project id. | <code title="">string</code> | ✓ |  |
| region | Compute region. | <code title="">string</code> | ✓ |  |
| zone | Compute zone. | <code title="">string</code> | ✓ |  |
| *boot_disk* | Boot disk properties. | <code title="object&#40;&#123;&#10;image &#61; string&#10;size  &#61; number&#10;type &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;image &#61; &#34;projects&#47;cos-cloud&#47;global&#47;images&#47;family&#47;cos-stable&#34;&#10;type &#61; &#34;pd-ssd&#34;&#10;size  &#61; 10&#10;&#125;">...</code> |
| *cos_config* | Configure COS logging and monitoring. | <code title="object&#40;&#123;&#10;logging    &#61; bool&#10;monitoring &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;logging    &#61; false&#10;monitoring &#61; true&#10;&#125;">...</code> |
| *files* | Map of files to create on the instances, path as key. Attributes default to 'root' and '0644', set to null if not needed. | <code title="map&#40;object&#40;&#123;&#10;content &#61; string&#10;attributes &#61; object&#40;&#123;&#10;owner       &#61; string&#10;permissions &#61; string&#10;&#125;&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *hostname* | Instance FQDN name. | <code title="">string</code> |  | <code title="">null</code> |
| *instance_count* | Number of instances to create (only for non-template usage). | <code title="">number</code> |  | <code title="">1</code> |
| *instance_type* | Instance type. | <code title="">string</code> |  | <code title="">f1-micro</code> |
| *labels* | Instance labels. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *metadata* | Instance metadata. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *min_cpu_platform* | Minimum CPU platform. | <code title="">string</code> |  | <code title="">null</code> |
| *options* | Instance options. | <code title="object&#40;&#123;&#10;allow_stopping_for_update &#61; bool&#10;can_ip_forward            &#61; bool&#10;deletion_protection       &#61; bool&#10;preemptible               &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;allow_stopping_for_update &#61; true&#10;can_ip_forward            &#61; false&#10;deletion_protection       &#61; false&#10;preemptible               &#61; false&#10;&#125;">...</code> |
| *service_account* | Service account email (leave empty to auto-create). | <code title="">string</code> |  | <code title=""></code> |
| *tags* | Instance tags. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["dns", "ssh"]</code> |
| *use_instance_template* | Create instance template instead of instances. | <code title="">bool</code> |  | <code title="">false</code> |

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
