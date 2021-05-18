# OpenShift Cluster Bootstrap

This example is a companion setup to the Python script in the parent folder, and is used to bootstrap OpenShift clusters on GCP. Refer to the documentation in the parent folder for usage instructions.

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| cluster_name | Name used for the cluster and DNS zone. | <code title="">string</code> | ✓ |  |
| domain | Domain name used to derive the DNS zone. | <code title="">string</code> | ✓ |  |
| fs_paths | Filesystem paths for commands and data, supports home path expansion. | <code title="object&#40;&#123;&#10;credentials       &#61; string&#10;config_dir        &#61; string&#10;openshift_install &#61; string&#10;pull_secret       &#61; string&#10;ssh_key           &#61; string&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| host_project | Shared VPC project and network configuration. | <code title="object&#40;&#123;&#10;default_subnet_name &#61; string&#10;masters_subnet_name &#61; string&#10;project_id          &#61; string&#10;vpc_name            &#61; string&#10;workers_subnet_name &#61; string&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| service_project | Service project configuration. | <code title="object&#40;&#123;&#10;project_id &#61; string&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| *allowed_ranges* | Ranges that can SSH to the boostrap VM and API endpoint. | <code title="list&#40;any&#41;">list(any)</code> |  | <code title="">["10.0.0.0/8"]</code> |
| *disk_encryption_key* | Optional CMEK for disk encryption. | <code title="object&#40;&#123;&#10;keyring    &#61; string&#10;location   &#61; string&#10;name       &#61; string&#10;project_id &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *install_config_params* | OpenShift cluster configuration. | <code title="object&#40;&#123;&#10;disk_size &#61; number&#10;network &#61; object&#40;&#123;&#10;cluster     &#61; string&#10;host_prefix &#61; number&#10;machine     &#61; string&#10;service     &#61; string&#10;&#125;&#41;&#10;proxy &#61; object&#40;&#123;&#10;http    &#61; string&#10;https   &#61; string&#10;noproxy &#61; string&#10;&#125;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;disk_size &#61; 16&#10;network &#61; &#123;&#10;cluster     &#61; &#34;10.128.0.0&#47;14&#34;&#10;host_prefix &#61; 23&#10;machine     &#61; &#34;10.0.0.0&#47;16&#34;&#10;service     &#61; &#34;172.30.0.0&#47;16&#34;&#10;&#125;&#10;proxy &#61; null&#10;&#125;">...</code> |
| *post_bootstrap_config* | Name of the service account for the machine operator. Removes bootstrap resources when set. | <code title="object&#40;&#123;&#10;machine_op_sa_prefix &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *region* | Region where resources will be created. | <code title="">string</code> |  | <code title="">europe-west1</code> |
| *rhcos_gcp_image* | RHCOS image used. | <code title="">string</code> |  | <code title="">projects/rhcos-cloud/global/images/rhcos-47-83-202102090044-0-gcp-x86-64</code> |
| *tags* | Additional tags for instances. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["ssh"]</code> |
| *zones* | Zones used for instances. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["b", "c", "d"]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| backend-health | Command to monitor API internal backend health. |  |
| bootstrap-ssh | Command to SSH to the bootstrap instance. |  |
| masters-ssh | Command to SSH to the master instances. |  |
<!-- END TFDOC -->
