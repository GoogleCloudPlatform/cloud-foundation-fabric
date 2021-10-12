# Google Cloud VPC Firewall - Yaml

This module implements a resource factory which allows the creation and management of [VPC firewall rules](https://cloud.google.com/vpc/docs/firewalls) through properly formatted `yaml` files.

`yaml` configurations are stored on a well-defined folder structure, whose entry point can be customized, and which represents and forces the resource hierarchy a firewall rule belongs to (Project > VPC > Firewall Rule).

This module also allows for a definition of variable templates, allowing for the definition and centralization of common CIDRs or Service Account lists, which enables re-using them across different policies.

## Example

### Terraform code

```hcl
module "vpc-firewall" {
  source           = "../../cloud-foundation-fabric/modules/resource-factories/vpc-firewall"
  config_folder    = "firewall/vpc"
  templates_folder = "firewall/templates"
}

# tftest:skip
```

### Configuration Structure

The naming convention for the `config_folder` folder **requires**

- the first directory layer to be named after the project ID which contains the VPC we're creating the firewall rules for
- the second directory layer to be named after the VPC we're creating the firewall rules for 
- `yaml` files contained in the "VPC" directory can be arbitrarily named, to allow for an easier logical grouping. 

Projects and VPCs should exist prior to running this module, or set as an explicit dependency to this module, leveraging `depends_on`.

The optional `templates_folder` folder can have two files. 

- `cidrs.yaml` - a YAML map defining lists of CIDRs
- `service_accounts.yaml` - a YAML map definint lists of Service Accounts

```bash
└── firewall
    ├── vpc
    │   ├── project-resource-factory-dev
    │   │   └── vpc-resource-factory-dev-one
    │   │   │   ├── frontend.yaml
    │   │   │   └── backend.yaml       
    │   │   └── vpc-resource-factory-dev-two
    │   │       ├── foo.yaml
    │   │       └── bar.yaml               
    │   └── project-resource-factory-prod
    │   │   └── vpc-resource-factory-prod-alpha
    │   │       ├── lorem.yaml
    │   │       └── ipsum.yaml       
    └── templates
        ├── cidrs.yaml
        └── service_accounts.yaml
```

### Rule definition format and structure

Firewall rules configuration should be placed in a set of yaml files in a folder/s. Firewall rule entry structure is following:

```yaml
rule-name:                  # descriptive name, naming convention is adjusted by the module
  description: "Allow icmp" # rule description
  action: allow             # `allow` or `deny`
  direction: INGRESS        # EGRESS or INGRESS
  ports:                    
    icmp: []                # {tcp, udp, icmp, all}: [ports], use [] for any port
  priority: 1000            # rule priority value, default value is 1000
  source_ranges:            # list of source ranges
    - 0.0.0.0/0
  destination_ranges:       # list of destination ranges
    - 0.0.0.0/0
  source_tags: ['some-tag'] # list of source tags
  source_service_accounts:  # list of source service accounts
    - myapp@myproject-id.iam.gserviceaccount.com
  target_tags: ['some-tag'] # list of target tags
  target_service_accounts:  # list of target service accounts
    - myapp@myproject-id.iam.gserviceaccount.com
  enable_logging: true      # `false` or `true`, logging is enabled when `true`
```

A sample configuration file might look like the following one:

```yaml
allow-healthchecks:
  description: "Allow traffic from healthcheck"
  direction: INGRESS
  action: allow
  priority: 1000
  source_ranges:
    - $healthcheck
  ports:
    tcp: ["80"]
  enable_logging: false

allow-http:
  description: "Allow traffic to LB backend"
  direction: INGRESS
  action: allow
  priority: 1000
  source_ranges:
    - 0.0.0.0/0
  target_service_accounts:
    - $web_frontends
  ports:
    tcp: ["80", "443"]
  enable_logging: false

```

with `firewall/templates/cidrs.yaml` defined as follows:

```yaml
healthcheck:
  - 35.191.0.0/16
  - 130.211.0.0/22
```

and `firewall/templates/service_accounts.yaml`:

```yaml
web_frontends:
  - web-frontends@project-wf1.iam.gserviceaccount.com
  - web-frontends@project-wf2.iam.gserviceaccount.com
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| config_folder | Relative path of the folder containing the hierarchical firewall configuration | <code title="">string</code> | ✓ |  |
| templates_folder | Relative path of the folder containing the cidr/service account templates | <code title="">string</code> | ✓ |  |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| vpc-firewall-rules | Generated VPC Firewall Rules |  |
<!-- END TFDOC -->