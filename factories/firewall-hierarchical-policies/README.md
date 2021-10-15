# Google Cloud Resource Factories - Hierarchical Firewall Policies

This module implements a resource factory which allows the creation and management of [hierarchical firewall policies](https://cloud.google.com/vpc/docs/firewall-policies) through properly formatted `yaml` files.

`yaml` configurations are stored on a well-defined folder structure, whose entry point can be customized, and which allows for simple grouping of policies by Organization ID.

This module also allows defining custom template variables, to centralize common CIDRs or Service Account lists, which enables re-using them across different policies.

## Example

### Terraform code

```hcl
module "hierarchical" {
  source           = "./modules/resource-factories/hierarchical-firewall"
  config_folder    = "firewall/hierarchical"
  templates_folder = "firewall/templates"
}
# tftest:skip
```

### Configuration Structure

The naming convention for the `config_folder` variable requires

- the first directory layer to be named after the organization ID we're creating the policies for
- each file to be named either `$folder_id-$description.yaml` (e.g. `1234567890-sharedinfra.yaml`) for policies applying to regular folders or `org.yaml` for the root folder.

Organizations and folders should exist prior to running this module, or set as an explicit dependency to this module, leveraging `depends_on`.

The optional `templates_folder` variable can have two files. 

- `cidrs.yaml` - a YAML map defining lists of CIDRs
- `service_accounts.yaml` - a YAML map defining lists of Service Accounts

Examples for both files are shown in the following section.

```bash
└── firewall
    ├── hierarchical
    │   ├── 31415926535                     
    │   │   ├── 1234567890-sharedinfra.yaml # Maps to folders/1234567890
    │   │   └── org.yaml                    # Maps to organizations/31415926535
    │   └── 27182818284
    │       └── 1234567891-sharedinfra.yaml # Maps to folders/1234567891
    └── templates
        ├── cidrs.yaml
        └── service_accounts.yaml
```

### Hierarchical firewall policies format and structure

The following syntax applies for both `$folder_id-$description.yaml` and for `org.yaml` files, with the former applying at the `$folder_id` level and the latter at the Organization level.

Each file can contain an arbitrary number of policies.

```yaml
# Policy name
allow-icmp:                            
  # Description
  description: Sample policy            
  # Direction {INGRESS, EGRESS}
  direction: INGRESS                   
  # Action {allow, deny}
  action: allow                         
  # Priority (must be unique on a node)
  priority: 1000                        
  # List of CIDRs this rule applies to (for INGRESS rules)
  source_ranges:                        
    - 0.0.0.0/0
  # List of CIDRs this rule applies to (for EGRESS rules)
  destination_ranges:                        
    - 0.0.0.0/0    
  # List of ports this rule applies to (empty array means all ports)
  ports:                                  
    tcp: []
    udp: []
    icmp: []                            
  # List of VPCs this rule applies to - a null value implies all VPCs
  target_resources: null  
  # Opt - List of target Service Accounts this rule applies to
  target_service_accounts:   
    - example-service-account@foobar.iam.gserviceaccount.com
  # Opt - Whether to enable logs - defaults to false           
  enable_logging: true                  
```

A sample configuration file might look like the following one:

```yaml
allow-icmp:
  description: Enable ICMP for all hosts
  direction: INGRESS
  action: allow
  priority: 1000
  source_ranges:
    - 0.0.0.0/0
  ports:
    icmp: []
  target_resources: null
  enable_logging: false

allow-ssh-from-onprem:
  description: Enable SSH for on prem hosts
  direction: INGRESS
  action: allow
  priority: 1001
  source_ranges:
    - $onprem
  ports:
    tcp: ["22"]
  target_resources: null
  enable_logging: false

allow-443-from-clients:
  description: Enable HTTPS for web clients
  direction: INGRESS
  action: allow
  priority: 1001
  source_ranges:
    - $web_clients
  ports:
    tcp: ["443"]
  target_resources: null
  target_service_accounts:   
    - $web_frontends
  enable_logging: false
```

with `firewall/templates/cidrs.yaml` defined as follows:

```yaml
onprem:
  - 10.0.0.0/8
  - 192.168.0.0/16

web_clients:
  - 172.16.0.0/16
  - 10.0.10.0/24   
  - 10.0.250.0/24
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
| hierarchical-firewall-rules | Generated Hierarchical Firewall Rules |  |
<!-- END TFDOC -->
