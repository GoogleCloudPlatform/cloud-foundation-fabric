# Apigee X Foundations

This  blueprint creates all the resources necessary to set up Apigee X on Google Cloud.

Apigee can be exposed to clients using Regional Internal Application Load Balancer, Global External Application Load Balancer or both. When using the Regional Internal Application Load Balancer, used self-managed certificates (including self-signed certificates generated in this same module). When using the Global External Application Load Balancer Google-managed certificates or self-managed certificates (including self-signed certificates generated in this same module). When using Cross-region Internal Application Load Balancer a certificate manager needs to be used and it needs to be created in the same project as Apigee.

Find below a few examples of different Apigee architectures that can be created using this module.

## Examples

* [Examples](#examples)
  * [Apigee X in service project with shared VPC peered and exposed with Global External Application LB and Regional Internal Application LB](#apigee-x-in-service-project-with-shared-vpc-peered-and-exposed-with-global-external-application-lb-and-regional-internal-application-lb)
  * [Apigee X in service project with local VPC peered and exposed using Global LB and Internal Cross-region Application LB](#apigee-x-in-service-project-with-local-vpc-peered-and-exposed-using-global-lb-and-internal-cross-region-application-lb)
  * [Apigee X in service project with peering disabled and exposed using Global LB](#apigee-x-in-service-project-with-peering-disabled-and-exposed-using-global-lb)
  * [Apigee X in standalone project with peering enabled and exposed with Regional Internal LB](#apigee-x-in-standalone-project-with-peering-enabled-and-exposed-with-regional-internal-lb)
  * [Apigee X in standalone project with peering disabled and exposed using Global External Application LB](#apigee-x-in-standalone-project-with-peering-disabled-and-exposed-using-global-external-application-lb)
* [Variables](#files)
* [Variables](#variables)
* [Outputs](#outputs)

### Apigee X in service project with shared VPC peered and exposed with Global External Application LB and Regional Internal Application LB

![Diagram](./diagram1.png)

```hcl
module "apigee-x-foundations" {
  source = "./fabric/blueprints/apigee/apigee-x-foundations"
  project_config = {
    billing_account_id = var.billing_account_id
    parent             = var.folder_id
    name               = var.project_id
    iam = {
      "roles/apigee.admin" = ["group:apigee-admins@myorg.com"]
    }
    shared_vpc_service_config = {
      host_project = "my-host-project"
    }
  }
  apigee_config = {
    addons_config = {
      api_security = true
    }
    organization = {
      analytics_region           = "europe-west1"
      api_consumer_data_location = "europe-west1"
      api_consumer_data_encryption_key_config = {
        auto_create = true
      }
      database_encryption_key_config = {
        auto_create = true
      }
      billing_type = "PAYG"
    }
    envgroups = {
      apis = [
        "apis.external.myorg.com",
        "apis.internal.myorg.com"
      ]
    }
    environments = {
      apis = {
        envgroups = ["apis"]
      }
    }
    instances = {
      europe-west1 = {
        external                      = true
        runtime_ip_cidr_range         = "10.0.0.0/22"
        troubleshooting_ip_cidr_range = "192.168.0.0/18"
        environments                  = ["apis"]
      }
    }
    endpoint_attachments = {
      endpoint-backend-ew1 = {
        region             = "europe-west1"
        service_attachment = "projects/a58971796302e0142p-tp/regions/europe-west4/serviceAttachments/my-service-attachment-ew1"
      }
    }
  }
  network_config = {
    shared_vpc = {
      name = "my-shared-vpc"
      subnets = {
        europe-west1 = "projects/my-host-project/regions/europe-west4/subnetworks/my-subnet-ew1"
      }
      subnets_psc = {
        europe-west1 = "projects/my-host-project/regions/europe-west4/subnetworks/my-subnet-psc-ew1"
      }
    }
  }
  ext_lb_config = {
    ssl_certificates = {
      create_configs = {
        default = {
          certificate = "PEM-Encoded certificate string"
          private_key = "PEM-Encoded private key string"
        }
      }
    }
  }
  int_lb_config = {
    ssl_certificates = {
      create_configs = {
        default = {
          certificate = "PEM-Encoded certificate string"
          private_key = "PEM-Encoded private key string"
        }
      }
    }
  }
}
# tftest modules=7 resources=50
```

### Apigee X in service project with local VPC peered and exposed using Global LB and Internal Cross-region Application LB

![Diagram](./diagram2.png)

```hcl
module "apigee-x-foundations" {
  source = "./fabric/blueprints/apigee/apigee-x-foundations"
  project_config = {
    billing_account_id = "1234-5678-0000"
    parent             = "folders/123456789"
    name               = "my-project"
    iam = {
      "roles/apigee.admin" = ["group:apigee-admins@myorg.com"]
    }
    shared_vpc_service_config = {
      host_project = "my-host-project"
    }
  }
  apigee_config = {
    addons_config = {
      api_security = true
    }
    organization = {
      analytics_region = "europe-west1"
      billing_type     = "PAYG"
    }
    envgroups = {
      apis = [
        "apis.external.myorg.com",
        "apis.internal.myorg.com"
      ]
    }
    environments = {
      apis = {
        envgroups = ["apis"]
        type      = "COMPREHENSIVE"
      }
    }
    instances = {
      europe-west1 = {
        runtime_ip_cidr_range         = "10.0.0.0/22"
        troubleshooting_ip_cidr_range = "192.168.0.0/28"
        environments                  = ["apis"]
      }
      europe-west4 = {
        runtime_ip_cidr_range         = "10.0.4.0/22"
        troubleshooting_ip_cidr_range = "192.168.0.16/28"
        environments                  = ["apis"]
      }
    }
    endpoint_attachments = {
      endpoint-backend-ew1 = {
        region             = "europe-west1"
        service_attachment = "projects/a58971796302e0142p-tp/regions/europe-west1/serviceAttachments/my-service-attachment-ew1"
        dns_names = [
          "backend.myorg.com"
        ]
      }
      endpoint-backend-ew4 = {
        region             = "europe-west1"
        service_attachment = "projects/a58971796302e0142p-tp/regions/europe-west4/serviceAttachments/my-service-attachment-ew4"
        dns_names = [
          "backend.myorg.com"
        ]
      }
    }
  }
  network_config = {
    shared_vpc = {
      name = "my-shared-vpc"
      subnets = {
        europe-west1 = "projects/my-host-project/regions/europe-west4/subnetworks/my-subnet-eu1"
        europe-west4 = "projects/my-host-project/regions/europe-west4/subnetworks/my-subnet-eu4"
      }
      subnets_psc = {
        europe-west1 = "projects/my-host-project/regions/europe-west4/subnetworks/my-subnet-psc-eu1"
        europe-west4 = "projects/my-host-project/regions/europe-west4/subnetworks/my-subnet-psc-eu4"
      }
    }
    apigee_vpc = {
      auto_create = true
    }
  }
  ext_lb_config = {
    ssl_certificates = {
      create_configs = {
        default = {
          certificate = "PEM-Encoded certificate string"
          private_key = "PEM-Encoded private key string"
        }
      }
    }
  }
  int_cross_region_lb_config = {
    certificate_manager_config = {
      certificates = {
        my-certificate-1 = {
          self_managed = {
            pem_certificate = "PEM-Encoded certificate string"
            pem_private_key = "PEM-Encoded private key string"
          }
        }
      }
    }
  }
}
# tftest modules=8 resources=62
```

### Apigee X in service project with peering disabled and exposed using Global LB

![Diagram](./diagram3.png)

```hcl
module "apigee-x-foundations" {
  source = "./fabric/blueprints/apigee/apigee-x-foundations"
  project_config = {
    billing_account_id = "1234-5678-0000"
    parent             = "folders/123456789"
    name               = "my-project"
    iam = {
      "roles/apigee.admin" = ["group:apigee-admins@myorg.com"]
    }
    shared_vpc_service_config = {
      host_project = "my-host-project"
    }
  }
  apigee_config = {
    addons_config = {
      api_security = true
    }
    organization = {
      analytics_region    = "europe-west1"
      disable_vpc_peering = true
    }
    envgroups = {
      apis = [
        "apis.external.myorg.com"
      ]
    }
    environments = {
      apis = {
        envgroups = ["apis"]
      }
    }
    instances = {
      europe-west1 = {
        runtime_ip_cidr_range         = "10.0.0.0/22"
        troubleshooting_ip_cidr_range = "192.168.0.0/18"
        environments                  = ["apis"]
      }
    }
    endpoint_attachments = {
      endpoint-backend-ew1 = {
        region             = "europe-west1"
        service_attachment = "projects/a58971796302e0142p-tp/regions/europe-west4/serviceAttachments/my-service-attachment-ew1"
      }
    }
    disable_vpc_peering = true
  }
  network_config = {
    shared_vpc = {
      name = "my-shared-vpc"
      subnets = {
        europe-west1 = "projects/my-host-project/regions/europe-west4/subnetworks/my-subnet-ew1"
      }
      subnets_psc = {
        europe-west1 = "projects/my-host-project/regions/europe-west4/subnetworks/my-subnet-psc-ew1"
      }
    }
  }
  ext_lb_config = {
    ssl_certificates = {
      create_configs = {
        default = {
          certificate = "PEM-Encoded certificate string"
          private_key = "PEM-Encoded private key string"
        }
      }
    }
  }
}
# tftest modules=4 resources=36
```

### Apigee X in standalone project with peering enabled and exposed with Regional Internal LB

![Diagram](./diagram4.png)

```hcl
module "apigee-x-foundations" {
  source = "./fabric/blueprints/apigee/apigee-x-foundations"
  project_config = {
    billing_account_id = "1234-5678-0000"
    parent             = "folders/123456789"
    name               = "my-project"
    iam = {
      "roles/apigee.admin" = ["group:apigee-admins@myorg.com"]
    }
  }
  apigee_config = {
    addons_config = {
      api_security = true
    }
    organization = {
      analytics_region = "europe-west1"
    }
    envgroups = {
      apis = [
        "apis.internal.myorg.com"
      ]
    }
    environments = {
      apis = {
        envgroups = ["apis"]
      }
    }
    instances = {
      europe-west1 = {
        runtime_ip_cidr_range         = "172.16.0.0/22"
        troubleshooting_ip_cidr_range = "192.168.0.0/18"
        environments                  = ["apis"]
      }
    }
    endpoint_attachments = {
      endpoint-backend-ew1 = {
        region             = "europe-west1"
        service_attachment = "projects/a58971796302e0142p-tp/regions/europe-west4/serviceAttachments/my-service-attachment-ew1"
        dns_names = [
          "backend.myorg.com"
        ]
      }
    }
  }
  network_config = {
    apigee_vpc = {
      subnets = {
        europe-west1 = {
          ip_cidr_range = "10.0.0.0/29"
        }
      }
      subnets_proxy_only = {
        europe-west1 = {
          ip_cidr_range = "10.1.0.0/26"
        }
      }
      subnets_psc = {
        europe-west1 = {
          ip_cidr_range = "10.0.1.0/29"
        }
      }
    }
  }
  int_lb_config = {
    ssl_certificates = {
      create_configs = {
        default = {
          certificate = "PEM-Encoded certificate string"
          private_key = "PEM-Encoded private key string"
        }
      }
    }
  }
}
# tftest modules=6 resources=48
```

### Apigee X in standalone project with peering disabled and exposed using Global External Application LB

![Diagram](./diagram5.png)

```hcl
module "apigee-x-foundations" {
  source = "./fabric/blueprints/apigee/apigee-x-foundations"
  project_config = {
    billing_account_id = "1234-5678-0000"
    parent             = "folders/123456789"
    name               = "my-project"
    iam = {
      "roles/apigee.admin" = ["group:apigee-admins@myorg.com"]
    }
  }
  apigee_config = {
    addons_config = {
      api_security = true
    }
    organization = {
      analytics_region    = "europe-west1"
      disable_vpc_peering = true
    }
    envgroups = {
      apis = [
        "apis.external.myorg.com",
        "apis.internal.myorg.com"
      ]
    }
    environments = {
      apis = {
        envgroups = ["apis"]
      }
    }
    instances = {
      europe-west1 = {
        environments = ["apis"]
      }
    }
    endpoint_attachments = {
      endpoint-backend-ew1 = {
        region             = "europe-west1"
        service_attachment = "projects/a58971796302e0142p-tp/regions/europe-west4/serviceAttachments/my-service-attachment-ew1"
      }
    }
    disable_vpc_peering = true
  }
  network_config = {
    apigee_vpc = {
      auto_create = true
      subnets = {
        europe-west1 = {
          ip_cidr_range = "10.0.0.0/29"
        }
      }
      subnets_psc = {
        europe-west1 = {
          ip_cidr_range = "10.0.1.0/29"
        }
      }
    }
  }
  ext_lb_config = {
    ssl_certificates = {
      create_configs = {
        default = {
          certificate = "PEM-Encoded certificate string"
          private_key = "PEM-Encoded private key string"
        }
      }
    }
  }
  enable_monitoring = true
}
# tftest modules=6 resources=63
```

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules | resources |
|---|---|---|---|
| [apigee.tf](./apigee.tf) | None | <code>apigee</code> |  |
| [dns.tf](./dns.tf) | None |  |  |
| [kms.tf](./kms.tf) | None | <code>kms</code> | <code>random_id</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>net-vpc</code> · <code>project</code> |  |
| [monitoring.tf](./monitoring.tf) | None | <code>cloud-function-v2</code> |  |
| [northbound.tf](./northbound.tf) | None | <code>certificate-manager</code> · <code>net-lb-app-ext</code> · <code>net-lb-app-int</code> · <code>net-lb-app-int-cross-region</code> | <code>google_compute_region_network_endpoint_group</code> · <code>google_compute_security_policy</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |  |
| [variables.tf](./variables.tf) | Module variables. |  |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [apigee_config](variables.tf#L17) | Apigee configuration. | <code title="object&#40;&#123;&#10;  addons_config &#61; optional&#40;object&#40;&#123;&#10;    advanced_api_ops    &#61; optional&#40;bool, false&#41;&#10;    api_security        &#61; optional&#40;bool, false&#41;&#10;    connectors_platform &#61; optional&#40;bool, false&#41;&#10;    integration         &#61; optional&#40;bool, false&#41;&#10;    monetization        &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  organization &#61; object&#40;&#123;&#10;    analytics_region &#61; optional&#40;string&#41;&#10;    api_consumer_data_encryption_key_config &#61; optional&#40;object&#40;&#123;&#10;      auto_create &#61; optional&#40;bool, false&#41;&#10;      id          &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    api_consumer_data_location &#61; optional&#40;string&#41;&#10;    billing_type               &#61; optional&#40;string&#41;&#10;    control_plane_encryption_key_config &#61; optional&#40;object&#40;&#123;&#10;      auto_create &#61; optional&#40;bool, false&#41;&#10;      id          &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    database_encryption_key_config &#61; optional&#40;object&#40;&#123;&#10;      auto_create &#61; optional&#40;bool, false&#41;&#10;      id          &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    description         &#61; optional&#40;string, &#34;Terraform-managed&#34;&#41;&#10;    disable_vpc_peering &#61; optional&#40;bool, false&#41;&#10;    display_name        &#61; optional&#40;string&#41;&#10;    properties          &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    retention           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#10;  envgroups &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  environments &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description       &#61; optional&#40;string&#41;&#10;    display_name      &#61; optional&#40;string&#41;&#10;    envgroups         &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    forward_proxy_uri &#61; optional&#40;string&#41;&#10;    iam               &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;      role    &#61; string&#10;      members &#61; list&#40;string&#41;&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;      role   &#61; string&#10;      member &#61; string&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        expression  &#61; string&#10;        title       &#61; string&#10;        description &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    node_config &#61; optional&#40;object&#40;&#123;&#10;      min_node_count &#61; optional&#40;number&#41;&#10;      max_node_count &#61; optional&#40;number&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    type &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  instances &#61; optional&#40;map&#40;object&#40;&#123;&#10;    disk_encryption_key_config &#61; optional&#40;object&#40;&#123;&#10;      auto_create &#61; optional&#40;bool, false&#41;&#10;      id          &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    environments                  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    external                      &#61; optional&#40;bool, true&#41;&#10;    runtime_ip_cidr_range         &#61; optional&#40;string&#41;&#10;    troubleshooting_ip_cidr_range &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  endpoint_attachments &#61; optional&#40;map&#40;object&#40;&#123;&#10;    region             &#61; string&#10;    service_attachment &#61; string&#10;    dns_names          &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [project_config](variables.tf#L333) | Project configuration. | <code title="object&#40;&#123;&#10;  billing_account_id      &#61; optional&#40;string&#41;&#10;  compute_metadata        &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  contacts                &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  custom_roles            &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  default_service_account &#61; optional&#40;string, &#34;keep&#34;&#41;&#10;  deletion_policy         &#61; optional&#40;string&#41;&#10;  descriptive_name        &#61; optional&#40;string&#41;&#10;  iam                     &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  group_iam               &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role    &#61; string&#10;    members &#61; list&#40;string&#41;&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  iam_bindings_additive &#61; optional&#40;map&#40;object&#40;&#123;&#10;    role   &#61; string&#10;    member &#61; string&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      expression  &#61; string&#10;      title       &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  labels              &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  lien_reason         &#61; optional&#40;string&#41;&#10;  logging_data_access &#61; optional&#40;map&#40;map&#40;list&#40;string&#41;&#41;&#41;, &#123;&#125;&#41;&#10;  log_exclusions      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  logging_sinks &#61; optional&#40;map&#40;object&#40;&#123;&#10;    bq_partitioned_table &#61; optional&#40;bool&#41;&#10;    description          &#61; optional&#40;string&#41;&#10;    destination          &#61; string&#10;    disabled             &#61; optional&#40;bool, false&#41;&#10;    exclusions           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;    filter               &#61; string&#10;    iam                  &#61; optional&#40;bool, true&#41;&#10;    type                 &#61; string&#10;    unique_writer        &#61; optional&#40;bool, true&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  metric_scopes &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  name          &#61; string&#10;  org_policies &#61; optional&#40;map&#40;object&#40;&#123;&#10;    inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;    reset               &#61; optional&#40;bool&#41;&#10;    rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;      allow &#61; optional&#40;object&#40;&#123;&#10;        all    &#61; optional&#40;bool&#41;&#10;        values &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      deny &#61; optional&#40;object&#40;&#123;&#10;        all    &#61; optional&#40;bool&#41;&#10;        values &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      enforce &#61; optional&#40;bool&#41; &#35; for boolean policies only.&#10;      condition &#61; optional&#40;object&#40;&#123;&#10;        description &#61; optional&#40;string&#41;&#10;        expression  &#61; optional&#40;string&#41;&#10;        location    &#61; optional&#40;string&#41;&#10;        title       &#61; optional&#40;string&#41;&#10;      &#125;&#41;, &#123;&#125;&#41;&#10;    &#125;&#41;&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  parent         &#61; optional&#40;string&#41;&#10;  prefix         &#61; optional&#40;string&#41;&#10;  project_create &#61; optional&#40;bool, true&#41;&#10;  vpc_sc &#61; optional&#40;object&#40;&#123;&#10;    perimeter_name    &#61; string&#10;    perimeter_bridges &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    is_dry_run        &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  services &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  shared_vpc_host_config &#61; optional&#40;object&#40;&#123;&#10;    enabled          &#61; bool&#10;    service_projects &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  shared_vpc_service_config &#61; optional&#40;object&#40;&#123;&#10;    host_project       &#61; string&#10;    service_agent_iam  &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    service_iam_grants &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;&#41;&#10;  tag_bindings &#61; optional&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [enable_monitoring](variables.tf#L116) | Boolean flag indicating whether an custom metric to monitor instances should be created in Cloud monitoring. | <code>bool</code> |  | <code>false</code> |  |
| [ext_lb_config](variables.tf#L122) | External application load balancer configuration. | <code title="object&#40;&#123;&#10;  address         &#61; optional&#40;string&#41;&#10;  log_sample_rate &#61; optional&#40;number&#41;&#10;  outlier_detection &#61; optional&#40;object&#40;&#123;&#10;    consecutive_errors                    &#61; optional&#40;number&#41;&#10;    consecutive_gateway_failure           &#61; optional&#40;number&#41;&#10;    enforcing_consecutive_errors          &#61; optional&#40;number&#41;&#10;    enforcing_consecutive_gateway_failure &#61; optional&#40;number&#41;&#10;    enforcing_success_rate                &#61; optional&#40;number&#41;&#10;    max_ejection_percent                  &#61; optional&#40;number&#41;&#10;    success_rate_minimum_hosts            &#61; optional&#40;number&#41;&#10;    success_rate_request_volume           &#61; optional&#40;number&#41;&#10;    success_rate_stdev_factor             &#61; optional&#40;number&#41;&#10;    base_ejection_time &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    interval &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  security_policy &#61; optional&#40;object&#40;&#123;&#10;    advanced_options_config &#61; optional&#40;object&#40;&#123;&#10;      json_parsing &#61; optional&#40;object&#40;&#123;&#10;        enable        &#61; optional&#40;bool, false&#41;&#10;        content_types &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      log_level &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    adaptive_protection_config &#61; optional&#40;object&#40;&#123;&#10;      layer_7_ddos_defense_config &#61; optional&#40;object&#40;&#123;&#10;        enable          &#61; optional&#40;bool, false&#41;&#10;        rule_visibility &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      auto_deploy_config &#61; optional&#40;object&#40;&#123;&#10;        load_threshold              &#61; optional&#40;number&#41;&#10;        confidence_threshold        &#61; optional&#40;number&#41;&#10;        impacted_baseline_threshold &#61; optional&#40;number&#41;&#10;        expiration_sec              &#61; optional&#40;number&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    rate_limit_threshold &#61; optional&#40;object&#40;&#123;&#10;      count        &#61; number&#10;      interval_sec &#61; number&#10;    &#125;&#41;&#41;&#10;    forbidden_src_ip_ranges &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    forbidden_regions       &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    preconfigured_waf_rules &#61; optional&#40;map&#40;object&#40;&#123;&#10;      sensitivity      &#61; optional&#40;number&#41;&#10;      opt_in_rule_ids  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;      opt_out_rule_ids &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  ssl_certificates &#61; object&#40;&#123;&#10;    certificate_ids &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    create_configs &#61; optional&#40;map&#40;object&#40;&#123;&#10;      certificate &#61; string&#10;      private_key &#61; string&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    managed_configs &#61; optional&#40;map&#40;object&#40;&#123;&#10;      domains     &#61; list&#40;string&#41;&#10;      description &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    self_signed_configs &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [int_cross_region_lb_config](variables.tf#L194) | Internal application load balancer configuration. | <code title="object&#40;&#123;&#10;  addresses       &#61; optional&#40;map&#40;string&#41;&#41;&#10;  log_sample_rate &#61; optional&#40;number&#41;&#10;  outlier_detection &#61; optional&#40;object&#40;&#123;&#10;    consecutive_errors                    &#61; optional&#40;number&#41;&#10;    consecutive_gateway_failure           &#61; optional&#40;number&#41;&#10;    enforcing_consecutive_errors          &#61; optional&#40;number&#41;&#10;    enforcing_consecutive_gateway_failure &#61; optional&#40;number&#41;&#10;    enforcing_success_rate                &#61; optional&#40;number&#41;&#10;    max_ejection_percent                  &#61; optional&#40;number&#41;&#10;    success_rate_minimum_hosts            &#61; optional&#40;number&#41;&#10;    success_rate_request_volume           &#61; optional&#40;number&#41;&#10;    success_rate_stdev_factor             &#61; optional&#40;number&#41;&#10;    base_ejection_time &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    interval &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  certificate_manager_config &#61; object&#40;&#123;&#10;    certificates &#61; map&#40;object&#40;&#123;&#10;      description &#61; optional&#40;string&#41;&#10;      labels      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;      location    &#61; optional&#40;string&#41;&#10;      scope       &#61; optional&#40;string&#41;&#10;      self_managed &#61; optional&#40;object&#40;&#123;&#10;        pem_certificate &#61; string&#10;        pem_private_key &#61; string&#10;      &#125;&#41;&#41;&#10;      managed &#61; optional&#40;object&#40;&#123;&#10;        domains            &#61; list&#40;string&#41;&#10;        dns_authorizations &#61; optional&#40;list&#40;string&#41;&#41;&#10;        issuance_config    &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    dns_authorizations &#61; optional&#40;map&#40;object&#40;&#123;&#10;      domain      &#61; string&#10;      description &#61; optional&#40;string&#41;&#10;      location    &#61; optional&#40;string&#41;&#10;      type        &#61; optional&#40;string&#41;&#10;      labels      &#61; optional&#40;map&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;    issuance_configs &#61; optional&#40;map&#40;object&#40;&#123;&#10;      ca_pool                    &#61; string&#10;      description                &#61; optional&#40;string&#41;&#10;      key_algorithm              &#61; string&#10;      labels                     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;      lifetime                   &#61; string&#10;      rotation_window_percentage &#61; number&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [int_lb_config](variables.tf#L254) | Internal application load balancer configuration. | <code title="object&#40;&#123;&#10;  addresses       &#61; optional&#40;map&#40;string&#41;&#41;&#10;  log_sample_rate &#61; optional&#40;number&#41;&#10;  outlier_detection &#61; optional&#40;object&#40;&#123;&#10;    consecutive_errors                    &#61; optional&#40;number&#41;&#10;    consecutive_gateway_failure           &#61; optional&#40;number&#41;&#10;    enforcing_consecutive_errors          &#61; optional&#40;number&#41;&#10;    enforcing_consecutive_gateway_failure &#61; optional&#40;number&#41;&#10;    enforcing_success_rate                &#61; optional&#40;number&#41;&#10;    max_ejection_percent                  &#61; optional&#40;number&#41;&#10;    success_rate_minimum_hosts            &#61; optional&#40;number&#41;&#10;    success_rate_request_volume           &#61; optional&#40;number&#41;&#10;    success_rate_stdev_factor             &#61; optional&#40;number&#41;&#10;    base_ejection_time &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    interval &#61; optional&#40;object&#40;&#123;&#10;      seconds &#61; number&#10;      nanos   &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  ssl_certificates &#61; object&#40;&#123;&#10;    certificate_ids &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    create_configs &#61; optional&#40;map&#40;object&#40;&#123;&#10;      certificate &#61; string&#10;      private_key &#61; string&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |  |
| [network_config](variables.tf#L290) | Network configuration. | <code title="object&#40;&#123;&#10;  shared_vpc &#61; optional&#40;object&#40;&#123;&#10;    name        &#61; string&#10;    subnets     &#61; map&#40;string&#41;&#10;    subnets_psc &#61; map&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  apigee_vpc &#61; optional&#40;object&#40;&#123;&#10;    name        &#61; optional&#40;string&#41;&#10;    auto_create &#61; optional&#40;bool, true&#41;&#10;    subnets &#61; optional&#40;map&#40;object&#40;&#123;&#10;      id            &#61; optional&#40;string&#41;&#10;      name          &#61; optional&#40;string&#41;&#10;      ip_cidr_range &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    subnets_proxy_only &#61; optional&#40;map&#40;object&#40;&#123;&#10;      name          &#61; optional&#40;string&#41;&#10;      ip_cidr_range &#61; string&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    subnets_psc &#61; optional&#40;map&#40;object&#40;&#123;&#10;      id            &#61; optional&#40;string&#41;&#10;      name          &#61; optional&#40;string&#41;&#10;      ip_cidr_range &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [apigee_vpc](outputs.tf#L17) | Apigee VPC. |  |  |
| [apigee_vpc_id](outputs.tf#L22) | Apigee VPC. |  |  |
| [apigee_vpc_self_link](outputs.tf#L27) | Apigee VPC. |  |  |
| [endpoint_attachment_hosts](outputs.tf#L31) | Endpoint attachment hosts. |  |  |
| [ext_lb_ip_address](outputs.tf#L36) | External IP address. |  |  |
| [instance_service_attachments](outputs.tf#L41) | Instance service attachments. |  |  |
| [int_cross_region_lb_ip_addresses](outputs.tf#L46) | Internal IP addresses. |  |  |
| [int_lb_ip_addresses](outputs.tf#L51) | Internal IP addresses. |  |  |
| [project](outputs.tf#L56) | Project. |  |  |
| [project_id](outputs.tf#L61) | Project id. |  |  |
<!-- END TFDOC -->
