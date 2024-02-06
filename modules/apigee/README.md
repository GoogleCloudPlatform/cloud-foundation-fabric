# Apigee

This module simplifies the creation of a Apigee resources (organization, environment groups, environment group attachments, environments, instances and instance attachments).

## Examples

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [Minimal example (CLOUD)](#minimal-example-cloud)
  - [Minimal example with existing organization (CLOUD)](#minimal-example-with-existing-organization-cloud)
  - [Disable VPC Peering (CLOUD)](#disable-vpc-peering-cloud)
  - [All resources (CLOUD)](#all-resources-cloud)
  - [All resources (HYBRID control plane)](#all-resources-hybrid-control-plane)
  - [New environment group](#new-environment-group)
  - [New environment](#new-environment)
  - [New instance (VPC Peering Provisioning Mode)](#new-instance-vpc-peering-provisioning-mode)
  - [New instance (Non VPC Peering Provisioning Mode)](#new-instance-non-vpc-peering-provisioning-mode)
  - [New endpoint attachment](#new-endpoint-attachment)
  - [Apigee add-ons](#apigee-add-ons)
  - [IAM](#iam)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

### Minimal example (CLOUD)

This example shows how to create to create an Apigee organization and deploy instance in it.

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = var.project_id
  organization = {
    display_name       = "Apigee"
    billing_type       = "PAYG"
    analytics_region   = "europe-west1"
    authorized_network = var.vpc.id
    runtime_type       = "CLOUD"
  }
  envgroups = {
    prod = ["prod.example.com"]
  }
  environments = {
    apis-prod = {
      display_name = "APIs prod"
      description  = "APIs Prod"
      envgroups    = ["prod"]
    }
  }
  instances = {
    europe-west1 = {
      environments                  = ["apis-prod"]
      runtime_ip_cidr_range         = "10.32.0.0/22"
      troubleshooting_ip_cidr_range = "10.64.0.0/28"
    }
  }
}
# tftest modules=1 resources=6 inventory=minimal-cloud.yaml
```

### Minimal example with existing organization (CLOUD)

This example shows how to create to work with an existing organization in the project. Note that in this case we don't specify the IP ranges for the instance, so it requests and allocates an available /22 and /28 CIDR block from Service Networking to deploy the instance.

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = var.project_id
  envgroups = {
    prod = ["prod.example.com"]
  }
  environments = {
    apis-prod = {
      display_name = "APIs prod"
      envgroups    = ["prod"]
    }
  }
  instances = {
    europe-west1 = {
      environments = ["apis-prod"]
    }
  }
}
# tftest modules=1 resources=5 inventory=minimal-cloud-no-org.yaml
```

### Disable VPC Peering (CLOUD)

When a new Apigee organization is created, it is automatically peered to the authorized network. You can prevent this from happening by using the `disable_vpc_peering` key in the `organization` variable, as shown below:

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = var.project_id
  organization = {
    display_name        = "Apigee"
    billing_type        = "PAYG"
    analytics_region    = "europe-west1"
    runtime_type        = "CLOUD"
    disable_vpc_peering = true
  }
  envgroups = {
    prod = ["prod.example.com"]
  }
  environments = {
    apis-prod = {
      display_name = "APIs prod"
      envgroups    = ["prod"]
    }
  }
  instances = {
    europe-west1 = {
      environments = ["apis-prod"]
    }
  }
}
# tftest modules=1 resources=6 inventory=no-peering.yaml
```

### All resources (CLOUD)

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  organization = {
    display_name            = "My Organization"
    description             = "My Organization"
    authorized_network      = "my-vpc"
    runtime_type            = "CLOUD"
    billing_type            = "PAYG"
    database_encryption_key = "123456789"
    analytics_region        = "europe-west1"
  }
  envgroups = {
    test = ["test.example.com"]
    prod = ["prod.example.com"]
  }
  environments = {
    apis-test = {
      display_name = "APIs test"
      description  = "APIs Test"
      envgroups    = ["test"]
    }
    apis-prod = {
      display_name = "APIs prod"
      description  = "APIs prod"
      envgroups    = ["prod"]
    }
  }
  instances = {
    europe-west1 = {
      runtime_ip_cidr_range         = "10.0.4.0/22"
      troubleshooting_ip_cidr_range = "10.1.1.0.0/28"
      environments                  = ["apis-test"]
    }
    europe-west3 = {
      runtime_ip_cidr_range         = "10.0.8.0/22"
      troubleshooting_ip_cidr_range = "10.1.16.0/28"
      environments                  = ["apis-prod"]
      enable_nat                    = true
    }
  }
  endpoint_attachments = {
    endpoint-backend-1 = {
      region             = "europe-west1"
      service_attachment = "projects/my-project-1/serviceAttachments/gkebackend1"
    }
    endpoint-backend-2 = {
      region             = "europe-west1"
      service_attachment = "projects/my-project-2/serviceAttachments/gkebackend2"
    }
  }
}
# tftest modules=1 resources=14
```

### All resources (HYBRID control plane)

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  organization = {
    display_name     = "My Organization"
    description      = "My Organization"
    runtime_type     = "HYBRID"
    analytics_region = "europe-west1"
  }
  envgroups = {
    test = ["test.example.com"]
    prod = ["prod.example.com"]
  }
  environments = {
    apis-test = {
      display_name = "APIs test"
      description  = "APIs Test"
      envgroups    = ["test"]
    }
    apis-prod = {
      display_name = "APIs prod"
      description  = "APIs prod"
      envgroups    = ["prod"]
    }
  }
}
# tftest modules=1 resources=7
```

### New environment group

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  envgroups = {
    test = ["test.example.com"]
  }
}
# tftest modules=1 resources=1
```

### New environment

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  environments = {
    apis-test = {
      display_name = "APIs test"
      description  = "APIs Test"
    }
  }
}
# tftest modules=1 resources=1
```

### New instance (VPC Peering Provisioning Mode)

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  instances = {
    europe-west1 = {
      runtime_ip_cidr_range         = "10.0.4.0/22"
      troubleshooting_ip_cidr_range = "10.1.1.0/28"
    }
  }
}
# tftest modules=1 resources=1
```

### New instance (Non VPC Peering Provisioning Mode)

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  organization = {
    display_name            = "My Organization"
    description             = "My Organization"
    runtime_type            = "CLOUD"
    billing_type            = "Pay-as-you-go"
    database_encryption_key = "123456789"
    analytics_region        = "europe-west1"
    disable_vpc_peering     = true
  }
  instances = {
    europe-west1 = {}
  }
}
# tftest modules=1 resources=2
```

### New endpoint attachment

Endpoint attachments allow to implement [Apigee southbound network patterns](https://cloud.google.com/apigee/docs/api-platform/architecture/southbound-networking-patterns-endpoints#create-the-psc-attachments).

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  endpoint_attachments = {
    endpoint-backend-1 = {
      region             = "europe-west1"
      service_attachment = "projects/my-project-1/serviceAttachments/gkebackend1"
    }
  }
}
# tftest modules=1 resources=1
```

### Apigee add-ons

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  addons_config = {
    monetization = true
  }
}
# tftest modules=1 resources=1
```

### IAM

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  organization = {
    display_name            = "My Organization"
    description             = "My Organization"
    authorized_network      = "my-vpc"
    runtime_type            = "CLOUD"
    billing_type            = "PAYG"
    database_encryption_key = "123456789"
    analytics_region        = "europe-west1"
  }
  envgroups = {
    test = ["test.example.com"]
    prod = ["prod.example.com"]
  }
  environments = {
    apis-test = {
      display_name = "APIs test"
      description  = "APIs Test"
      envgroups    = ["test"]
      iam = {
        "roles/apigee.environmentAdmin" = ["group:apigee-env-admin@myorg.com"]
      }
      iam_bindings_additive = {
        viewer = {
          role   = "roles/viewer"
          member = "user:user1@myorg.com"
        }
      }
    }
    apis-prod = {
      display_name = "APIs prod"
      description  = "APIs prod"
      envgroups    = ["prod"]
      iam_bindings = {
        apigee-env-admin = {
          role    = "roles/apigee.environmentAdmin"
          members = ["group:apigee-env-admin@myorg.com"]
        }
      }
    }
  }
}
# tftest modules=1 resources=10
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L126) | Project ID. | <code>string</code> | ✓ |  |
| [addons_config](variables.tf#L17) | Addons configuration. | <code title="object&#40;&#123;&#10;  advanced_api_ops    &#61; optional&#40;bool, false&#41;&#10;  api_security        &#61; optional&#40;bool, false&#41;&#10;  connectors_platform &#61; optional&#40;bool, false&#41;&#10;  integration         &#61; optional&#40;bool, false&#41;&#10;  monetization        &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [endpoint_attachments](variables.tf#L29) | Endpoint attachments. | <code title="map&#40;object&#40;&#123;&#10;  region             &#61; string&#10;  service_attachment &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [envgroups](variables.tf#L39) | Environment groups (NAME => [HOSTNAMES]). | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [environments](variables.tf#L46) | Environments. | <code title="map&#40;object&#40;&#123;&#10;  display_name    &#61; optional&#40;string&#41;&#10;  description     &#61; optional&#40;string, &#34;Terraform-managed&#34;&#41;&#10;  deployment_type &#61; optional&#40;string&#41;&#10;  api_proxy_type  &#61; optional&#40;string&#41;&#10;  type            &#61; optional&#40;string&#41;&#10;  node_config &#61; optional&#40;object&#40;&#123;&#10;    min_node_count &#61; optional&#40;number&#41;&#10;    max_node_count &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role    &#61; string&#10;    members &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role   &#61; string&#10;    member &#61; string&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  envgroups &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [instances](variables.tf#L73) | Instances ([REGION] => [INSTANCE]). | <code title="map&#40;object&#40;&#123;&#10;  name                          &#61; optional&#40;string&#41;&#10;  display_name                  &#61; optional&#40;string&#41;&#10;  description                   &#61; optional&#40;string, &#34;Terraform-managed&#34;&#41;&#10;  runtime_ip_cidr_range         &#61; optional&#40;string&#41;&#10;  troubleshooting_ip_cidr_range &#61; optional&#40;string&#41;&#10;  disk_encryption_key           &#61; optional&#40;string&#41;&#10;  consumer_accept_list          &#61; optional&#40;list&#40;string&#41;&#41;&#10;  enable_nat                    &#61; optional&#40;bool, false&#41;&#10;  environments                  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [organization](variables.tf#L98) | Apigee organization. If set to null the organization must already exist. | <code title="object&#40;&#123;&#10;  display_name            &#61; optional&#40;string&#41;&#10;  description             &#61; optional&#40;string, &#34;Terraform-managed&#34;&#41;&#10;  authorized_network      &#61; optional&#40;string&#41;&#10;  runtime_type            &#61; optional&#40;string, &#34;CLOUD&#34;&#41;&#10;  billing_type            &#61; optional&#40;string&#41;&#10;  database_encryption_key &#61; optional&#40;string&#41;&#10;  analytics_region        &#61; optional&#40;string, &#34;europe-west1&#34;&#41;&#10;  retention               &#61; optional&#40;string&#41;&#10;  disable_vpc_peering     &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [endpoint_attachment_hosts](outputs.tf#L17) | Endpoint hosts. |  |
| [envgroups](outputs.tf#L22) | Environment groups. |  |
| [environments](outputs.tf#L27) | Environment. |  |
| [instances](outputs.tf#L32) | Instances. |  |
| [nat_ips](outputs.tf#L37) | NAT IP addresses used in instances. |  |
| [org_id](outputs.tf#L45) | Organization ID. |  |
| [org_name](outputs.tf#L50) | Organization name. |  |
| [organization](outputs.tf#L55) | Organization. |  |
| [service_attachments](outputs.tf#L60) | Service attachments. |  |
<!-- END TFDOC -->
