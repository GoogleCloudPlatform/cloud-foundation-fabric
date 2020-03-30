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
| name | Instances base name. | <code title="">string</code> | ✓ |  |
| network_interfaces | Network interfaces configuration. Use self links for Shared VPC, set addresses to null if not needed. | <code title="list&#40;object&#40;&#123;&#10;nat        &#61; bool&#10;network    &#61; string&#10;subnetwork &#61; string&#10;addresses &#61; object&#40;&#123;&#10;internal &#61; list&#40;string&#41;&#10;external &#61; list&#40;string&#41;&#10;&#125;&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> | ✓ |  |
| project_id | Project id. | <code title="">string</code> | ✓ |  |
| region | Compute region. | <code title="">string</code> | ✓ |  |
| zone | Compute zone. | <code title="">string</code> | ✓ |  |
| *attached_disk_defaults* | Defaults for attached disks options. | <code title="object&#40;&#123;&#10;auto_delete &#61; bool&#10;mode        &#61; string&#10;type &#61; string&#10;source      &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;auto_delete &#61; true&#10;source      &#61; null&#10;mode        &#61; &#34;READ_WRITE&#34;&#10;type &#61; &#34;pd-ssd&#34;&#10;&#125;">...</code> |
| *attached_disks* | Additional disks, if options is null defaults will be used in its place. | <code title="list&#40;object&#40;&#123;&#10;name  &#61; string&#10;image &#61; string&#10;size  &#61; string&#10;options &#61; object&#40;&#123;&#10;auto_delete &#61; bool&#10;mode        &#61; string&#10;source      &#61; string&#10;type &#61; string&#10;&#125;&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="">[]</code> |
| *boot_disk* | Boot disk properties. | <code title="object&#40;&#123;&#10;image &#61; string&#10;size  &#61; number&#10;type &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;image &#61; &#34;projects&#47;cos-cloud&#47;global&#47;images&#47;family&#47;cos-stable&#34;&#10;type &#61; &#34;pd-ssd&#34;&#10;size  &#61; 10&#10;&#125;">...</code> |
| *group* | Instance group (for instance use). | <code title="object&#40;&#123;&#10;named_ports &#61; map&#40;number&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *group_manager* | Instance group manager (for template use). | <code title="object&#40;&#123;&#10;auto_healing_policies &#61; object&#40;&#123;&#10;health_check      &#61; string&#10;initial_delay_sec &#61; number&#10;&#125;&#41;&#10;named_ports &#61; map&#40;number&#41;&#10;options &#61; object&#40;&#123;&#10;target_pools       &#61; list&#40;string&#41;&#10;wait_for_instances &#61; bool&#10;&#125;&#41;&#10;regional    &#61; bool&#10;target_size &#61; number&#10;update_policy &#61; object&#40;&#123;&#10;type &#61; string &#35; OPPORTUNISTIC &#124; PROACTIVE&#10;minimal_action       &#61; string &#35; REPLACE &#124; RESTART&#10;min_ready_sec        &#61; number&#10;max_surge_type       &#61; string &#35; fixed &#124; percent&#10;max_surge            &#61; number&#10;max_unavailable_type &#61; string&#10;max_unavailable      &#61; number&#10;&#125;&#41;&#10;versions &#61; list&#40;object&#40;&#123;&#10;name              &#61; string&#10;instance_template &#61; string&#10;target_type       &#61; string &#35; fixed &#124; percent&#10;target_size       &#61; number&#10;&#125;&#41;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *hostname* | Instance FQDN name. | <code title="">string</code> |  | <code title="">null</code> |
| *instance_count* | Number of instances to create (only for non-template usage). | <code title="">number</code> |  | <code title="">1</code> |
| *instance_type* | Instance type. | <code title="">string</code> |  | <code title="">f1-micro</code> |
| *labels* | Instance labels. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *metadata* | Instance metadata. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *min_cpu_platform* | Minimum CPU platform. | <code title="">string</code> |  | <code title="">null</code> |
| *options* | Instance options. | <code title="object&#40;&#123;&#10;allow_stopping_for_update &#61; bool&#10;can_ip_forward            &#61; bool&#10;deletion_protection       &#61; bool&#10;preemptible               &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;allow_stopping_for_update &#61; true&#10;can_ip_forward            &#61; false&#10;deletion_protection       &#61; false&#10;preemptible               &#61; false&#10;&#125;">...</code> |
| *scratch_disks* | Scratch disks configuration. | <code title="object&#40;&#123;&#10;count     &#61; number&#10;interface &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;count     &#61; 0&#10;interface &#61; &#34;NVME&#34;&#10;&#125;">...</code> |
| *service_account* | Service account email. Unused if service account is auto-created. | <code title="">string</code> |  | <code title="">null</code> |
| *service_account_create* | Auto-create service account. | <code title="">bool</code> |  | <code title="">false</code> |
| *service_account_scopes* | Scopes applied to service account. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *tags* | Instance tags. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *template* | Path to the cloud init template, use 'preset:xxxx' for module presets. | <code title="">string</code> |  | <code title="">preset:generic</code> |
| *template_variables* | Path to the template variables used to render the cloud init template. | <code title="map&#40;any&#41;">map(any)</code> |  | <code title="">{}</code> |
| *use_instance_template* | Create instance template instead of instances. | <code title="">bool</code> |  | <code title="">false</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| external_ips | Instance main interface external IP addresses. |  |
| group | Instance group resource. |  |
| group_manager | Instance group resource. |  |
| instances | Instance resources. |  |
| internal_ips | Instance main interface internal IP addresses. |  |
| names | Instance names. |  |
| self_links | Instance self links. |  |
| service_account | Service account resource. |  |
| service_account_email | Service account email. |  |
| service_account_iam_email | Service account email. |  |
| template | Template resource. |  |
| template_name | Template name. |  |
<!-- END TFDOC -->
