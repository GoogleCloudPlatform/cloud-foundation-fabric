# Minimal Project Factory

This module implements a minimal, opinionated project factory (see [Factories](../README.md) for rationale) that allows for the creation of projects.

While the module can be invoked by manually populating the required variables, its interface is meant for the massive creation of resources leveraging a set of well-defined YaML documents, as shown in the examples below.

The Project Factory is meant to be executed by a Service Account (or a regular user) having this minimal set of permissions over your resources:

* **Org level** - a custom role for networking operations including the following permissions
  * `"compute.organizations.enableXpnResource"`,
  * `"compute.organizations.disableXpnResource"`,
  * `"compute.subnetworks.setIamPolicy"`,
  * `"dns.networks.bindPrivateDNSZone"`
  * and role `"roles/orgpolicy.policyAdmin"`
* **on each folder** where projects will be created
  * `"roles/logging.admin"` 
  * `"roles/owner"` 
  * `"roles/resourcemanager.folderAdmin"` 
  * `"roles/resourcemanager.projectCreator"`
* **on the host project** for the Shared VPC/s
  * `"roles/browser"`       
  * `"roles/compute.viewer"`
  * `"roles/dns.admin"` 

## Example

### Directory structure

```
.
├── data
│   ├── defaults.yaml
│   └── projects
│       ├── project-example-one.yaml
│       ├── project-example-two.yaml
│       └── project-example-three.yaml
├── main.tf
└── terraform.tfvars

```

### Terraform code

```tfvars
# ./terraform.tfvars
data_dir = "data/projects/"
defaults_file = "data/defaults.yaml"
```

```hcl
# ./main.tf

locals {
  defaults = yamldecode(file(var.defaults_file))
  projects = {
    for f in fileset("${var.data_dir}", "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.data_dir}/${f}"))
  }
}

module "projects" {
  source             = "./factories/project-factory"
  for_each           = local.projects
  defaults           = local.defaults
  project_id         = each.key
  billing_account_id = try(each.value.billing_account_id, null)
  billing_alert      = try(each.value.billing_alert, null)
  dns_zones          = try(each.value.dns_zones, [])
  essential_contacts = try(each.value.essential_contacts, [])
  folder_id          = each.value.folder_id
  group_iam          = try(each.value.group_iam, {})
  iam                = try(each.value.iam, {})
  kms_service_agents = try(each.value.kms, {})
  labels             = try(each.value.labels, {})
  org_policies       = try(each.value.org_policies, null)
  secrets            = try(each.value.secrets, {})
  service_accounts   = try(each.value.service_accounts, {})
  services           = try(each.value.services, [])
  services_iam       = try(each.value.services_iam, {})
  vpc                = try(each.value.vpc, null)
}
```

### Projects configuration

```yaml
# ./data/defaults.yaml
# The following applies as overrideable defaults for all projects
# All attributes are required

billing_account_id: 012345-67890A-BCDEF0
billing_alert:
  amount: 1000
  thresholds:
    current: [0.5, 0.8]
    forecasted: [0.5, 0.8]
  credit_treatment: INCLUDE_ALL_CREDITS
environment_dns_zone: prod.gcp.example.com
essential_contacts: []
labels:
  environment: production
  department: legal
  application: my-legal-bot
notification_channels: []
shared_vpc_self_link: https://www.googleapis.com/compute/v1/projects/project-example-host-project/global/networks/vpc-one
vpc_host_project: project-example-host-project

```

```yaml
# ./data/projects/project-example-one.yaml
# One file per project - projects will be named after the filename

# [opt] Billing account id - overrides default if set
billing_account_id: 012345-67890A-BCDEF0
                    
# [opt] Billing alerts config - overrides default if set
billing_alert:      
  amount: 10
  thresholds:
    current:
      - 0.5
      - 0.8
    forecasted: []

# [opt] DNS zones to be created as children of the environment_dns_zone defined in defaults 
dns_zones:          
    - lorem
    - ipsum

# [opt] Contacts for billing alerts and important notifications 
essential_contacts:                  
  - team-a-contacts@example.com

# Folder the project will be created as children of
folder_id: folders/012345678901

# [opt] Authoritative IAM bindings in group => [roles] format
group_iam:          
  test-team-foobar@fast-lab-0.gcp-pso-italy.net:
    - roles/compute.admin

# [opt] Authoritative IAM bindings in role => [principals] format
# Generally used to grant roles to service accounts external to the project
iam:                                    
  roles/compute.admin:
    - serviceAccount:service-account

# [opt] Service robots and keys they will be assigned as cryptoKeyEncrypterDecrypter 
# in service => [keys] format
kms_service_agents:                 
  compute: [key1, key2]
  storage: [key1, key2]

# [opt] Labels for the project - merged with the ones defined in defaults
labels:             
  environment: prod

# [opt] Org policy overrides defined at project level
org_policies:       
  policy_boolean:
    constraints/compute.disableGuestAttributesAccess: true
  policy_list:
    constraints/compute.trustedImageProjects:
      inherit_from_parent: null
      status: true
      suggested_value: null
      values:
        - projects/fast-prod-iac-core-0

# [opt] Service account to create for the project and their roles on the project
# in name => [roles] format
service_accounts:                      
  another-service-account:
    - roles/compute.admin
  my-service-account:
    - roles/compute.admin

# [opt] APIs to enable on the project. 
services:           
  - storage.googleapis.com
  - stackdriver.googleapis.com
  - compute.googleapis.com

# [opt] Roles to assign to the robots service accounts in robot => [roles] format
services_iam:       
  compute:
    - roles/storage.objectViewer

 # [opt] VPC setup. 
 # If set enables the `compute.googleapis.com` service and configures 
 # service project attachment
vpc:               

  # [opt] If set, enables the container API
  gke_setup:        

    # Grants "roles/container.hostServiceAgentUser" to the container robot if set 
    enable_host_service_agent: false

    # Grants  "roles/compute.securityAdmin" to the container robot if set                    
    enable_security_admin: true

  # Host project the project will be service project of                    
  host_project: fast-prod-net-spoke-0

  # [opt] Subnets in the host project where principals will be granted networkUser
  # in region/subnet-name => [principals]                    
  subnets_iam:                          
    europe-west1/prod-default-ew1: []
      - user:foobar@example.com
      - serviceAccount:service-account1
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [billing_account_id](variables.tf#L17) | Billing account id. | <code>string</code> | ✓ |  |
| [folder_id](variables.tf#L69) | Folder ID for the folder where the project will be created. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L118) | Project id. | <code>string</code> | ✓ |  |
| [billing_alert](variables.tf#L22) | Billing alert configuration. | <code title="object&#40;&#123;&#10;  amount &#61; number&#10;  thresholds &#61; object&#40;&#123;&#10;    current    &#61; list&#40;number&#41;&#10;    forecasted &#61; list&#40;number&#41;&#10;  &#125;&#41;&#10;  credit_treatment &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [defaults](variables.tf#L35) | Project factory default values. | <code title="object&#40;&#123;&#10;  billing_account_id &#61; string&#10;  billing_alert &#61; object&#40;&#123;&#10;    amount &#61; number&#10;    thresholds &#61; object&#40;&#123;&#10;      current    &#61; list&#40;number&#41;&#10;      forecasted &#61; list&#40;number&#41;&#10;    &#125;&#41;&#10;    credit_treatment &#61; string&#10;  &#125;&#41;&#10;  environment_dns_zone  &#61; string&#10;  essential_contacts    &#61; list&#40;string&#41;&#10;  labels                &#61; map&#40;string&#41;&#10;  notification_channels &#61; list&#40;string&#41;&#10;  shared_vpc_self_link  &#61; string&#10;  vpc_host_project      &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [dns_zones](variables.tf#L57) | DNS private zones to create as child of var.defaults.environment_dns_zone. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [essential_contacts](variables.tf#L63) | Email contacts to be used for billing and GCP notifications. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [group_iam](variables.tf#L74) | Custom IAM settings in group => [role] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L80) | Custom IAM settings in role => [principal] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [kms_service_agents](variables.tf#L86) | KMS IAM configuration in as service => [key]. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L92) | Labels to be assigned at project level. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [org_policies](variables.tf#L98) | Org-policy overrides at project level. | <code title="object&#40;&#123;&#10;  policy_boolean &#61; map&#40;bool&#41;&#10;  policy_list &#61; map&#40;object&#40;&#123;&#10;    inherit_from_parent &#61; bool&#10;    suggested_value     &#61; string&#10;    status              &#61; bool&#10;    values              &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [prefix](variables.tf#L112) | Prefix used for the project id. | <code>string</code> |  | <code>null</code> |
| [service_accounts](variables.tf#L123) | Service accounts to be created, and roles to assign them. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_identities_iam](variables.tf#L136) | Custom IAM settings for service identities in service => [role] format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [services](variables.tf#L129) | Services to be enabled for the project. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [vpc](variables.tf#L143) | VPC configuration for the project. | <code title="object&#40;&#123;&#10;  host_project &#61; string&#10;  gke_setup &#61; object&#40;&#123;&#10;    enable_security_admin     &#61; bool&#10;    enable_host_service_agent &#61; bool&#10;  &#125;&#41;&#10;  subnets_iam &#61; map&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [project](outputs.tf#L19) | The project resource as return by the `project` module |  |
| [project_id](outputs.tf#L29) | Project ID. |  |

<!-- END TFDOC -->
