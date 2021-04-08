# Google Compute Engine VM module

This module can operate in two distinct modes:

- instance creation, with optional unmanaged group
- instance template creation

In both modes, an optional service account can be created and assigned to either instances or template. If you need a managed instance group when using the module in template mode, refer to the [`compute-mig`](../compute-mig) module.

## Examples

### Instance using defaults

The simplest example leverages defaults for the boot disk image and size, and uses a service account created by the module. Multiple instances can be managed via the `instance_count` variable.

```hcl
module "simple-vm-example" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  region     = var.region
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  service_account_create = true
  instance_count = 1
}
# tftest:modules=1:resources=2

```

### Disk sources

Attached disks can be created and optionally initialized from a pre-existing source, or attached to VMs when pre-existing. The `source` and `source_type` attributes of the `attached_disks` variable allows several modes of operation:

- `source_type = "image"` can be used with zonal disks in instances and templates, set `source` to the image name or link
- `source_type = "snapshot"` can be used with instances only, set `source` to the snapshot name or link
- `source_type = "attach"` can be used for both instances and templates to attach an existing disk, set source to the name (for zonal disks) or link (for regional disks) of the existing disk to attach; no disk will be created
- `source_type = null` can be used where an empty disk is needed, `source` becomes irrelevant and can be left null

This is an example of attaching a pre-existing regional PD to a new instance:

```hcl
module "simple-vm-example" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  region     = var.region
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  attached_disks = [{
    name        = "repd-1"
    size        = null
    source_type = "attach"
    source      = "regions/${var.region}/disks/repd-test-1"
    options = {
      auto_delete = false
      mode        = null
      regional    = true
      type        = null
    }
  }]
  service_account_create = true
}
# tftest:modules=1:resources=2
```

And the same example for an instance template (where not using the full self link of the disk triggers recreation of the template)

```hcl
module "simple-vm-example" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  region     = var.region
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  attached_disks = [{
    name        = "repd"
    size        = null
    source_type = "attach"
    source      = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/disks/repd-test-1"
    options = {
      auto_delete = false
      mode        = null
      regional    = true
      type        = null
    }
  }]
  service_account_create = true
  use_instance_template  = true
}
# tftest:modules=1:resources=2
```

### Disk encryption with Cloud KMS

This example shows how to control disk encryption via the the `encryption` variable, in this case the self link to a KMS CryptoKey that will be used to encrypt boot and attached disk. Managing the key with the `../kms` module is of course possible, but is not shown here.

```hcl
module "kms-vm-example" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  region     = var.region
  name       = "kms-test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  attached_disks = [
    {
      name  = "attached-disk"
      size        = 10
      source      = null
      source_type = null
      options     = null
    }
  ]
  service_account_create = true
  instance_count         = 1
  boot_disk = {
    image        = "projects/debian-cloud/global/images/family/debian-10"
    type         = "pd-ssd"
    size         = 10
  }
  encryption = {
    encrypt_boot            = true
    disk_encryption_key_raw = null
    kms_key_self_link       = var.kms_key.self_link
  }
}
# tftest:modules=1:resources=3
```

### Using Alias IPs

This example shows how add additional [Alias IPs](https://cloud.google.com/vpc/docs/alias-ip) to your VM.

```hcl
module "vm-with-alias-ips" {
  source     = "./modules/compute-vm"
  project_id = "my-project"
  region     = "europe-west1"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
    alias_ips = {
      alias1 = [
        "10.16.0.10/32", # alias1 IP for first instance
        "10.16.0.11/32", # alias1 IP for second instance
        "10.16.0.12/32", # alias1 IP for third instance
      ]
    }
  }]
  service_account_create = true
  instance_count         = 3
}
# tftest:modules=1:resources=4
```

### Instance template

This example shows how to use the module to manage an instance template that defines an additional attached disk for each instance, and overrides defaults for the boot disk image and service account.

```hcl
module "cos-test" {
  source     = "./modules/compute-vm"
  project_id = "my-project"
  region     = "europe-west1"
  name       = "test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  instance_count = 1
  boot_disk      = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  attached_disks = [
    {
      name        = "disk-1"
      size        = 10
      source      = null
      source_type = null
      options     = null
    }
  ]
  service_account        = "vm-default@my-project.iam.gserviceaccount.com"
  use_instance_template  = true
}
# tftest:modules=1:resources=1
```

### Instance group

If an instance group is needed when operating in instance mode, simply set the `group` variable to a non null map. The map can contain named port declarations, or be empty if named ports are not needed.

```hcl
locals {
  cloud_config = "my cloud config"
}

module "instance-group" {
  source     = "./modules/compute-vm"
  project_id = "my-project"
  region     = "europe-west1"
  name       = "ilb-test"
  network_interfaces = [{
    network    = var.vpc.self_link
    subnetwork = var.subnet.self_link
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  boot_disk = {
    image = "projects/cos-cloud/global/images/family/cos-stable"
    type  = "pd-ssd"
    size  = 10
  }
  service_account        = var.service_account.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  metadata = {
    user-data = local.cloud_config
  }
  group = { named_ports = {} }
}
# tftest:modules=1:resources=2
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| name | Instances base name. | <code title="">string</code> | ✓ |  |
| network_interfaces | Network interfaces configuration. Use self links for Shared VPC, set addresses and alias_ips to null if not needed. | <code title="list&#40;object&#40;&#123;&#10;nat        &#61; bool&#10;network    &#61; string&#10;subnetwork &#61; string&#10;addresses &#61; object&#40;&#123;&#10;internal &#61; list&#40;string&#41;&#10;external &#61; list&#40;string&#41;&#10;&#125;&#41;&#10;alias_ips &#61; map&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> | ✓ |  |
| project_id | Project id. | <code title="">string</code> | ✓ |  |
| region | Compute region. | <code title="">string</code> | ✓ |  |
| *attached_disk_defaults* | Defaults for attached disks options. | <code title="object&#40;&#123;&#10;auto_delete &#61; bool&#10;mode        &#61; string&#10;regional    &#61; bool&#10;type &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;auto_delete &#61; true&#10;mode        &#61; &#34;READ_WRITE&#34;&#10;regional    &#61; false&#10;type &#61; &#34;pd-ssd&#34;&#10;&#125;">...</code> |
| *attached_disks* | Additional disks, if options is null defaults will be used in its place. Source type is one of 'image' (zonal disks in vms and template), 'snapshot' (vm), 'existing', and null. | <code title="list&#40;object&#40;&#123;&#10;name        &#61; string&#10;size        &#61; string&#10;source      &#61; string&#10;source_type &#61; string&#10;options &#61; object&#40;&#123;&#10;auto_delete &#61; bool&#10;mode        &#61; string&#10;regional    &#61; bool&#10;type &#61; string&#10;&#125;&#41;&#10;&#125;&#41;&#41;">list(object({...}))</code> |  | <code title="&#91;&#93;&#10;validation &#123;&#10;condition &#61; length&#40;&#91;&#10;for d in var.attached_disks : d if&#40;&#10;d.source_type &#61;&#61; null&#10;&#124;&#124;&#10;contains&#40;&#91;&#34;image&#34;, &#34;snapshot&#34;, &#34;attach&#34;&#93;, coalesce&#40;d.source_type, &#34;1&#34;&#41;&#41;&#10;&#41;&#10;&#93;&#41; &#61;&#61; length&#40;var.attached_disks&#41;&#10;error_message &#61; &#34;Source type must be one of &#39;image&#39;, &#39;snapshot&#39;, &#39;attach&#39;, null.&#34;&#10;&#125;">...</code> |
| *boot_disk* | Boot disk properties. | <code title="object&#40;&#123;&#10;image &#61; string&#10;size  &#61; number&#10;type &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;image &#61; &#34;projects&#47;debian-cloud&#47;global&#47;images&#47;family&#47;debian-10&#34;&#10;type &#61; &#34;pd-ssd&#34;&#10;size  &#61; 10&#10;&#125;">...</code> |
| *can_ip_forward* | Enable IP forwarding. | <code title="">bool</code> |  | <code title="">false</code> |
| *confidential_compute* | Enable Confidential Compute for these instances. | <code title="">bool</code> |  | <code title="">false</code> |
| *enable_display* | Enable virtual display on the instances | <code title="">bool</code> |  | <code title="">false</code> |
| *encryption* | Encryption options. Only one of kms_key_self_link and disk_encryption_key_raw may be set. If needed, you can specify to encrypt or not the boot disk. | <code title="object&#40;&#123;&#10;encrypt_boot            &#61; bool&#10;disk_encryption_key_raw &#61; string&#10;kms_key_self_link       &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *group* | Define this variable to create an instance group for instances. Disabled for template use. | <code title="object&#40;&#123;&#10;named_ports &#61; map&#40;number&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *hostname* | Instance FQDN name. | <code title="">string</code> |  | <code title="">null</code> |
| *iam* | IAM bindings in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *instance_count* | Number of instances to create (only for non-template usage). | <code title="">number</code> |  | <code title="">1</code> |
| *instance_type* | Instance type. | <code title="">string</code> |  | <code title="">f1-micro</code> |
| *labels* | Instance labels. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *metadata* | Instance metadata. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *metadata_list* | List of instance metadata that will be cycled through. Ignored for template use. | <code title="list&#40;map&#40;string&#41;&#41;">list(map(string))</code> |  | <code title="">[]</code> |
| *min_cpu_platform* | Minimum CPU platform. | <code title="">string</code> |  | <code title="">null</code> |
| *options* | Instance options. | <code title="object&#40;&#123;&#10;allow_stopping_for_update &#61; bool&#10;deletion_protection       &#61; bool&#10;preemptible               &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;allow_stopping_for_update &#61; true&#10;deletion_protection       &#61; false&#10;preemptible               &#61; false&#10;&#125;">...</code> |
| *scratch_disks* | Scratch disks configuration. | <code title="object&#40;&#123;&#10;count     &#61; number&#10;interface &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;count     &#61; 0&#10;interface &#61; &#34;NVME&#34;&#10;&#125;">...</code> |
| *service_account* | Service account email. Unused if service account is auto-created. | <code title="">string</code> |  | <code title="">null</code> |
| *service_account_create* | Auto-create service account. | <code title="">bool</code> |  | <code title="">false</code> |
| *service_account_scopes* | Scopes applied to service account. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *shielded_config* | Shielded VM configuration of the instances. | <code title="object&#40;&#123;&#10;enable_secure_boot          &#61; bool&#10;enable_vtpm                 &#61; bool&#10;enable_integrity_monitoring &#61; bool&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *single_name* | Do not append progressive count to instance name. | <code title="">bool</code> |  | <code title="">false</code> |
| *tags* | Instance tags. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *use_instance_template* | Create instance template instead of instances. | <code title="">bool</code> |  | <code title="">false</code> |
| *zones* | Compute zone, instance will cycle through the list, defaults to the 'b' zone in the region. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| external_ips | Instance main interface external IP addresses. |  |
| groups | Instance group resources. |  |
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

## TODO

- [ ] add support for instance groups
