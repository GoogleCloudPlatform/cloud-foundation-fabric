# Google Cloud Resource Factories - VPC Subnets

This module implements a resource factory which allows the creation and management of subnets through properly formatted `yaml` files.

`yaml` configurations are stored on a well-defined folder structure, whose entry point can be customized, and which allows for simple grouping of subnets by Project > VPC.

## Example

### Terraform code

```hcl
module "subnets" {
  source        = "./modules/resource-factories/subnets"
  config_folder = "subnets"
}
# tftest:skip
```

### Configuration Structure

The directory structure implies the project and the VPC each subnet belongs to.
Per the structure below, a subnet named `subnet-a` (after filename `subnet-a.yaml`) will be created on VPC `vpc-alpha-one` which belongs to project `project-alpha`.

Projects and VPCs should exist prior to running this module, or set as an explicit dependency to this module, leveraging `depends_on`.

```bash
└── subnets
    ├── project-alpha
    │   ├── vpc-alpha-one
    │   │   ├── subnet-a.yaml
    │   │   └── subnet-b.yaml
    │   └── vpc-alpha-two
    │       └── subnet-c.yaml  
    └── project-bravo
        └── vpc-bravo-one
            └── subnet-d.yaml
```

### Subnet definition format and structure

```yaml
region: europe-west1              # Region where the subnet will be creted
description: Sample description   # Description
ip_cidr_range: 10.0.0.0/24        # Primary IP range for the subnet
private_ip_google_access: false   # Opt- Enables PGA. Defaults to true
iam_users: ["foobar@example.com"] # Opt- Users to grant compute/networkUser to
iam_groups: ["lorem@example.com"] # Opt- Groups to grant compute/networkUser to
iam_service_accounts: ["foobar@project-id.iam.gserviceaccount.com"]         
                                  # Opt- SAs to grant compute/networkUser to
secondary_ip_ranges:              # Opt- List of secondary IP ranges
  - name: secondary-range-a       # Name for the secondary range 
    ip_cidr_range: 192.168.0.0/24 # IP range for the secondary range

```

<!-- BEGIN TFDOC -->
## Variables

| name          | description                                                     |             type             | required | default |
| ------------- | --------------------------------------------------------------- | :--------------------------: | :------: | :-----: |
| config_folder | Relative path of the folder containing the subnet configuration | <code title="">string</code> |    ✓     |         |

## Outputs

| name   | description       | sensitive |
| ------ | ----------------- | :-------: |
| subnet | Generated subnets |           |
<!-- END TFDOC -->
