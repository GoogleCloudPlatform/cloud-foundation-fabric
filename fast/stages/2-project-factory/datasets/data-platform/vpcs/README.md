# Project-Local VPCs

This folder can contain YAML files defining VPCs that are local to specific projects.
The structure should follow the `net-vpc-factory` pattern:

1.  Create a folder for the VPC (e.g., `my-vpc-0`).
2.  Inside that folder, create a `.config.yaml` file.
3.  Define the VPC configuration in `.config.yaml`.

Example `.config.yaml` (see `domain-0/.config.yaml`):

```yaml
name: domain-0
project_id: $project_ids:shared-0 # Use context interpolation for project IDs
subnets:
  - name: default
    ip_cidr_range: 10.0.0.0/24
    region: $locations:primary
```

Note: You must also enable the `vpcs` factory path in your `terraform.tfvars` or `*.auto.tfvars` file if it's not enabled by default:

```hcl
factories_config = {
  paths = {
    vpcs = "vpcs"
  }
}
```
