# Apigee

This module simplifies the creation of a Apigee resources (organization, environment groups, environment group attachments, environments, instances and instance attachments).

## Example

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
      display_name    = "APIs test"
      description     = "APIs Test"
      envgroups       = ["test"]
    }
    apis-prod = {
      display_name    = "APIs prod"
      description     = "APIs prod"
      envgroups       = ["prod"]
      iam = {
        "roles/viewer" = ["group:devops@myorg.com"]
      }
    }
  }
  instances = {
    instance-test-ew1 = {
      region            = "europe-west1"
      environments      = ["apis-test"]
      psa_ip_cidr_range = "10.0.4.0/22"
    }
    instance-prod-ew3 = {
      region            = "europe-west3"
      environments      = ["apis-prod"]
      psa_ip_cidr_range = "10.0.5.0/22"
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
    display_name            = "My Organization"
    description             = "My Organization"
    runtime_type            = "HYBRID"
    analytics_region        = "europe-west1"
  }
  envgroups = {
    test = ["test.example.com"]
    prod = ["prod.example.com"]
  }
  environments = {
    apis-test = {
      display_name    = "APIs test"
      description     = "APIs Test"
      envgroups       = ["test"]
    }
    apis-prod = {
      display_name    = "APIs prod"
      description     = "APIs prod"
      envgroups       = ["prod"]
      iam = {
        "roles/viewer" = ["group:devops@myorg.com"]
      }
    }
  }
}
# tftest modules=1 resources=8
```

### New environment group in an existing organization

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

### New environment in an existing environment group

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  environments = {
    apis-test = {
      display_name    = "APIs test"
      description     = "APIs Test"
      envgroups       = ["test"]
    }
  }
}
# tftest modules=1 resources=2
```

### New instance attached to an existing environment

```hcl
module "apigee" {
  source     = "./fabric/modules/apigee"
  project_id = "my-project"
  instances = {
    instance-test-ew1 = {
      region            = "europe-west1"
      environments      = ["apis-test"]
      psa_ip_cidr_range = "10.0.4.0/22"
    }
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
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L75) | Project ID. | <code>string</code> | ✓ |  |
| [endpoint_attachments](variables.tf#L17) | Endpoint attachments. | <code title="map&#40;object&#40;&#123;&#10;  region             &#61; string&#10;  service_attachment &#61; string&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [envgroups](variables.tf#L26) | Environment groups (NAME => [HOSTNAMES]). | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>null</code> |
| [environments](variables.tf#L32) | Environments. | <code title="map&#40;object&#40;&#123;&#10;  display_name &#61; optional&#40;string&#41;&#10;  description  &#61; optional&#40;string, &#34;Terraform-managed&#34;&#41;&#10;  node_config &#61; optional&#40;object&#40;&#123;&#10;    min_node_count &#61; optional&#40;number&#41;&#10;    max_node_count &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  iam       &#61; optional&#40;map&#40;list&#40;string&#41;&#41;&#41;&#10;  envgroups &#61; list&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [instances](variables.tf#L47) | Instances. | <code title="map&#40;object&#40;&#123;&#10;  display_name         &#61; optional&#40;string&#41;&#10;  description          &#61; optional&#40;string, &#34;Terraform-managed&#34;&#41;&#10;  region               &#61; string&#10;  environments         &#61; list&#40;string&#41;&#10;  psa_ip_cidr_range    &#61; string&#10;  disk_encryption_key  &#61; optional&#40;string&#41;&#10;  consumer_accept_list &#61; optional&#40;list&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [organization](variables.tf#L61) | Apigee organization. If set to null the organization must already exist. | <code title="object&#40;&#123;&#10;  display_name            &#61; optional&#40;string&#41;&#10;  description             &#61; optional&#40;string, &#34;Terraform-managed&#34;&#41;&#10;  authorized_network      &#61; optional&#40;string&#41;&#10;  runtime_type            &#61; optional&#40;string, &#34;CLOUD&#34;&#41;&#10;  billing_type            &#61; optional&#40;string&#41;&#10;  database_encryption_key &#61; optional&#40;string&#41;&#10;  analytics_region        &#61; optional&#40;string, &#34;europe-west1&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [envgroups](outputs.tf#L17) | Environment groups. |  |
| [environments](outputs.tf#L22) | Environment. |  |
| [instances](outputs.tf#L27) | Instances. |  |
| [org_id](outputs.tf#L32) | Organization ID. |  |
| [org_name](outputs.tf#L37) | Organization name. |  |
| [organization](outputs.tf#L42) | Organization. |  |
| [service_attachments](outputs.tf#L47) | Service attachments. |  |

<!-- END TFDOC -->
