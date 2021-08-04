# Google compute Engine from image
This module creates a list of VM from images specified in `yaml` files. 

## Example

### Terraform code

module "vm_images" {
  source             = "./modules/compute-vm-from-image"
  config_directories = ["${path.module}/images"]
  project_id         = "test"

}
# tftest:skip
```

### Images definition format and structure

VM images information should be placed in yaml files in folders. Mandatory fields are name and source_machine_image. The others are not mandatory and override the properties in the machine image. 
Structure is following:

```yaml
myfirstimage: # descriptive name
  name: vm1   # name of the vm that will be created (mandatory)
  source_machine_image: vm-image-1   # name of the image from where the vm will be created (mandatory)
  zone: europe-west2-a               # zone where the vm will be created (mandatory)
  network: vpc-region-2              # vpc network where the vm will be created (mandatory)
  subnetwork: region-2-sub-a         # vpc subnet where the vm will be created (mandatory)
  subnetwork_project: prove-321007   # project_id where the vm will be created (mandatory)
  metadata: {web-server: server1, team: dev} # metadata (override)

  ```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| config_directories | List of paths to folders where vm  are stored in yaml format. Folder may include subfolders with configuration files. Files suffix must be `.yaml` | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |
| project_id | Project Id where resources will be created. | <code title="">string</code> | ✓ |  |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| external_ips | Instance main interface external IP addresses. |  |
| instances | Instance resources. |  |
| internal_ips | Instance main interface internal IP addresses. |  |
| names | Instance names. |  |
| self_links | Instance self links. |  |
<!-- END TFDOC -->