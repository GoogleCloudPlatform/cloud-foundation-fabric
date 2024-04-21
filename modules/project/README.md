# Project Module

This module implements the creation and management of one GCP project including IAM, organization policies, Shared VPC host or service attachment, service API activation, and tag attachment. It also offers a convenient way to refer to managed service identities (aka robot service accounts) for APIs.

## TOC

<!-- BEGIN TOC -->
- [TOC](#toc)
- [Basic Project Creation](#basic-project-creation)
- [IAM](#iam)
  - [Authoritative IAM](#authoritative-iam)
  - [Additive IAM](#additive-iam)
  - [Service Identities and Authoritative IAM](#service-identities-and-authoritative-iam)
  - [Service Identities Requiring Manual IAM Grants](#service-identities-requiring-manual-iam-grants)
- [Shared VPC](#shared-vpc)
- [Organization Policies](#organization-policies)
  - [Organization Policy Factory](#organization-policy-factory)
- [Log Sinks](#log-sinks)
- [Data Access Logs](#data-access-logs)
- [Cloud KMS Encryption Keys](#cloud-kms-encryption-keys)
- [Attaching Tags](#attaching-tags)
- [Project-scoped Tags](#project-scoped-tags)
- [Custom Roles](#custom-roles)
  - [Custom Roles Factory](#custom-roles-factory)
- [Quotas](#quotas)
- [Quotas factory](#quotas-factory)
- [VPC Service Controls](#vpc-service-controls)
- [Outputs](#outputs)
  - [Managing project related configuration without creating it](#managing-project-related-configuration-without-creating-it)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Basic Project Creation

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
}
# tftest modules=1 resources=3 inventory=basic.yaml e2e
```

## IAM

IAM is managed via several variables that implement different features and levels of control:

- `iam` and `iam_by_principals` configure authoritative bindings that manage individual roles exclusively, and are internally merged
- `iam_bindings` configure authoritative bindings with optional support for conditions, and are not internally merged with the previous two variables
- `iam_bindings_additive` configure additive bindings via individual role/member pairs with optional support  conditions

The authoritative and additive approaches can be used together, provided different roles are managed by each. Some care must also be taken with the `iam_by_principals` variable to ensure that variable keys are static values, so that Terraform is able to compute the dependency graph.

Be mindful about service identity roles when using authoritative IAM, as you might inadvertently remove a role from a [service identity](https://cloud.google.com/iam/docs/service-account-types#google-managed) or default service account. For example, using `roles/editor` with `iam` or `iam_principals` will remove the default permissions for the Cloud Services identity. A simple workaround for these scenarios is described below.

### Authoritative IAM

The `iam` variable is based on role keys and is typically used for service accounts, or where member values can be dynamic and would create potential problems in the underlying `for_each` cycle.

```hcl
locals {
  gke_service_account = "my_gke_service_account"
}

module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  iam = {
    "roles/container.hostServiceAgentUser" = [
      "serviceAccount:${local.gke_service_account}"
    ]
  }
}
# tftest modules=1 resources=4 inventory=iam-authoritative.yaml
```

The `iam_by_principals` variable uses [principals](https://cloud.google.com/iam/docs/principal-identifiers) as keys and is a convenient way to assign roles to humans following Google's best practices. The end result is readable code that also serves as documentation.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  iam_by_principals = {
    "group:${var.group_email}" = [
      "roles/cloudasset.owner",
      "roles/cloudsupport.techSupportEditor",
      "roles/iam.securityReviewer",
      "roles/logging.admin",
    ]
  }
}
# tftest modules=1 resources=5 inventory=iam-group.yaml e2e
```

The `iam_bindings` variable behaves like a more verbose version of `iam`, and allows setting binding-level IAM conditions.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  iam_bindings = {
    iam_admin_conditional = {
      members = [
        "group:${var.group_email}"
      ]
      role = "roles/resourcemanager.projectIamAdmin"
      condition = {
        title      = "delegated_network_user_one"
        expression = <<-END
          api.getAttribute(
            'iam.googleapis.com/modifiedGrantsByRole', []
          ).hasOnly([
            'roles/compute.networkAdmin'
          ])
        END
      }
    }
  }
}
# tftest modules=1 resources=4 inventory=iam-bindings.yaml e2e
```

### Additive IAM

Additive IAM is typically used where bindings for specific roles are controlled by different modules or in different Terraform stages. One common example is a host project managed by the networking team, and a project factory that manages service projects and needs to assign `roles/networkUser` on the host project.

The `iam_bindings_additive` variable allows setting individual role/principal binding pairs. Support for IAM conditions is implemented like for `iam_bindings` above.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "compute.googleapis.com"
  ]
  iam_bindings_additive = {
    group-owner = {
      member = "group:${var.group_email}"
      role   = "roles/owner"
    }
  }
}
# tftest modules=1 resources=3 inventory=iam-bindings-additive.yaml e2e
```

### Service Identities and Authoritative IAM

As mentioned above, there are cases where authoritative management of specific IAM roles results in removal of default bindings from service identities. One example is outlined below, with a simple workaround leveraging the `service_accounts` output to identify the service identity. A full list of service identities and their roles can be found [here](https://cloud.google.com/iam/docs/service-agents).

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  iam = {
    "roles/editor" = [
      "serviceAccount:${module.project.service_accounts.cloud_services}"
    ]
  }
}
# tftest modules=1 resources=2 e2e
```

### Service Identities Requiring Manual IAM Grants

The module will create service identities at project creation instead of creating of them at the time of first use. This allows granting these service identities roles in other projects, something which is usually necessary in a Shared VPC context.  

You can grant roles to service identities using the following construct:

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "apigee.googleapis.com",
  ]
  iam = {
    "roles/apigee.serviceAgent" = [
      "serviceAccount:${module.project.service_accounts.robots.apigee}"
    ]
  }
}
# tftest modules=1 resources=4 e2e
```

This table lists all affected services and roles that you need to grant to service identities

| service                            | service identity     | role                                   |
|------------------------------------|----------------------|----------------------------------------|
| apigee.googleapis.com              | apigee               | roles/apigee.serviceAgent              |
| artifactregistry.googleapis.com    | artifactregistry     | roles/artifactregistry.serviceAgent    |
| cloudasset.googleapis.com          | cloudasset           | roles/cloudasset.serviceAgent          |
| cloudbuild.googleapis.com          | cloudbuild           | roles/cloudbuild.builds.builder        |
| dataform.googleapis.com            | dataform             | roles/dataform.serviceAgent            |
| dataplex.googleapis.com            | dataplex             | roles/dataplex.serviceAgent            |
| dlp.googleapis.com                 | dlp                  | roles/dlp.serviceAgent                 |
| gkehub.googleapis.com              | fleet                | roles/gkehub.serviceAgent              |
| meshconfig.googleapis.com          | servicemesh          | roles/anthosservicemesh.serviceAgent   |
| multiclusteringress.googleapis.com | multicluster-ingress | roles/multiclusteringress.serviceAgent |
| pubsub.googleapis.com              | pubsub               | roles/pubsub.serviceAgent              |
| sqladmin.googleapis.com            | sqladmin             | roles/cloudsql.serviceAgent            |

## Shared VPC

The module allows managing Shared VPC status for both hosts and service projects, and control of IAM bindings for API service identities.

Project service association for VPC host projects can be

- authoritatively managed in the host project by enabling Shared VPC and specifying the set of service projects, or
- additively managed in service projects by enabling Shared VPC in the host project and then "attaching" each service project independently

IAM bindings in the host project for API service identities can be managed from service projects in two different ways:

- via the `service_identity_iam` attribute, by specifying the set of roles and service agents
- via the `service_iam_grants` attribute that leverages a [fixed list of roles for each service](./sharedvpc-agent-iam.yaml), by specifying a list of services
- via the `service_identity_subnet_iam` attribute, by providing a map of `"<region>/<subnet_name>"` -> `[ "<service_identity>", (...)]`, to grant `compute.networkUser` role on subnet level to service identity

While the first method is more explicit and readable, the second method is simpler and less error prone as all appropriate roles are predefined for all required service agents (eg compute and cloud services). You can mix and match as the two sets of bindings are then internally combined.

This example shows a simple configuration with a host project, and a service project independently attached with granular IAM bindings for service identities.

```hcl
module "host-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "host"
  parent          = var.folder_id
  prefix          = var.prefix
  shared_vpc_host_config = {
    enabled = true
  }
}

module "service-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "service"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "container.googleapis.com",
    "run.googleapis.com"
  ]
  shared_vpc_service_config = {
    host_project = module.host-project.project_id
    service_identity_iam = {
      "roles/compute.networkUser" = [
        "cloudservices", "container-engine"
      ]
      "roles/vpcaccess.user" = [
        "cloudrun"
      ]
      "roles/container.hostServiceAgentUser" = [
        "container-engine"
      ]
    }
  }
}
# tftest modules=2 resources=10 inventory=shared-vpc.yaml e2e
```

This example shows a similar configuration, with the simpler way of defining IAM bindings for service identities. The list of services passed to `service_iam_grants` uses the same module's outputs to establish a dependency, as service identities are only typically available after service (API) activation.

```hcl
module "host-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "host"
  parent          = var.folder_id
  prefix          = var.prefix
  shared_vpc_host_config = {
    enabled = true
  }
}

module "service-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "service"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "container.googleapis.com",
  ]
  shared_vpc_service_config = {
    host_project = module.host-project.project_id
    # reuse the list of services from the module's outputs
    service_iam_grants = module.service-project.services
  }
}
# tftest modules=2 resources=9 inventory=shared-vpc-auto-grants.yaml e2e
```

The `compute.networkUser` role for identities other than API services (e.g. users, groups or service accounts) can be managed via the `network_users` attribute, by specifying the list of identities. Avoid using dynamically generated lists, as this attribute is involved in a `for_each` loop and may result in Terraform errors.

Note that this configuration grants the role at project level which results in the identities being able to configure resources on all the VPCs and subnets belonging to the host project. The most reliable way to restrict which subnets can be used on the newly created project is via the `compute.restrictSharedVpcSubnetworks` organization policy. For more information on the Org Policy configuration check the corresponding [Organization Policy section](#organization-policies). The following example details this configuration.

```hcl
module "host-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "host"
  parent          = var.folder_id
  prefix          = var.prefix
  shared_vpc_host_config = {
    enabled = true
  }
}

module "service-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "service"
  parent          = var.folder_id
  prefix          = var.prefix
  org_policies = {
    "compute.restrictSharedVpcSubnetworks" = {
      rules = [{
        allow = {
          values = ["projects/host/regions/europe-west1/subnetworks/prod-default-ew1"]
        }
      }]
    }
  }
  services = [
    "container.googleapis.com",
  ]
  shared_vpc_service_config = {
    host_project  = module.host-project.project_id
    network_users = ["group:${var.group_email}"]
    # reuse the list of services from the module's outputs
    service_iam_grants = module.service-project.services
  }
}
# tftest modules=2 resources=11 inventory=shared-vpc-host-project-iam.yaml e2e
```

In specific cases it might make sense to selectively grant the `compute.networkUser` role for service identities at the subnet level, and while that is best done via org policies it's also supported by this module. In this example, Compute service identity and `team-1@example.com` Google Group will be granted compute.networkUser in the `gce` subnet defined in `europe-west1` region in the `host` project (not included in the example) via the `service_identity_subnet_iam` and `network_subnet_users` attributes.

```hcl
module "host-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "host"
  parent          = var.folder_id
  prefix          = var.prefix
  shared_vpc_host_config = {
    enabled = true
  }
}

module "service-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "service"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "compute.googleapis.com",
  ]
  shared_vpc_service_config = {
    host_project = module.host-project.project_id
    service_identity_subnet_iam = {
      "europe-west1/gce" = ["compute"]
    }
    network_subnet_users = {
      "europe-west1/gce" = ["group:team-1@example.com"]
    }
  }
}
# tftest modules=2 resources=7 inventory=shared-vpc-subnet-grants.yaml
```

## Organization Policies

To manage organization policies, the `orgpolicy.googleapis.com` service should be enabled in the quota project.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  org_policies = {
    "compute.disableGuestAttributesAccess" = {
      rules = [{ enforce = true }]
    }
    "compute.skipDefaultNetworkCreation" = {
      rules = [{ enforce = true }]
    }
    "iam.disableServiceAccountKeyCreation" = {
      rules = [{ enforce = true }]
    }
    "iam.disableServiceAccountKeyUpload" = {
      rules = [
        {
          condition = {
            expression  = "resource.matchTagId('tagKeys/1234', 'tagValues/1234')"
            title       = "condition"
            description = "test condition"
            location    = "somewhere"
          }
          enforce = true
        },
        {
          enforce = false
        }
      ]
    }
    "iam.allowedPolicyMemberDomains" = {
      rules = [{
        allow = {
          values = ["C0xxxxxxx", "C0yyyyyyy"]
        }
      }]
    }
    "compute.trustedImageProjects" = {
      rules = [{
        allow = {
          values = ["projects/my-project"]
        }
      }]
    }
    "compute.vmExternalIpAccess" = {
      rules = [{ deny = { all = true } }]
    }
  }
}
# tftest modules=1 resources=8 inventory=org-policies.yaml e2e
```

### Organization Policy Factory

Organization policies can be loaded from a directory containing YAML files where each file defines one or more constraints. The structure of the YAML files is exactly the same as the `org_policies` variable.

Note that constraints defined via `org_policies` take precedence over those in `org_policies_data_path`. In other words, if you specify the same constraint in a YAML file *and* in the `org_policies` variable, the latter will take priority.

The example below deploys a few organization policies split between two YAML files.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  factories_config = {
    org_policies = "configs/org-policies/"
  }
}
# tftest modules=1 resources=8 files=boolean,list inventory=org-policies.yaml e2e
```

```yaml
# tftest-file id=boolean path=configs/org-policies/boolean.yaml

---
# Terraform will be unable to decode this file if it does not contain valid YAML
# You can retain `---` (start of the document) to indicate an empty document.

compute.disableGuestAttributesAccess:
  rules:
  - enforce: true
compute.skipDefaultNetworkCreation:
  rules:
  - enforce: true
iam.disableServiceAccountKeyCreation:
  rules:
  - enforce: true
iam.disableServiceAccountKeyUpload:
  rules:
  - condition:
      description: test condition
      expression: resource.matchTagId('tagKeys/1234', 'tagValues/1234')
      location: somewhere
      title: condition
    enforce: true
  - enforce: false
```

```yaml
# tftest-file id=list path=configs/org-policies/list.yaml

---
# Terraform will be unable to decode this file if it does not contain valid YAML
# You can retain `---` (start of the document) to indicate an empty document.

compute.trustedImageProjects:
  rules:
  - allow:
      values:
      - projects/my-project
compute.vmExternalIpAccess:
  rules:
  - deny:
      all: true
iam.allowedPolicyMemberDomains:
  rules:
  - allow:
      values:
      - C0xxxxxxx
      - C0yyyyyyy
```

## Log Sinks

```hcl
module "gcs" {
  source        = "./fabric/modules/gcs"
  project_id    = var.project_id
  name          = "gcs_sink"
  prefix        = var.prefix
  force_destroy = true
}

module "dataset" {
  source     = "./fabric/modules/bigquery-dataset"
  project_id = var.project_id
  id         = "bq_sink"
  options    = { delete_contents_on_destroy = true }
}

module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "pubsub_sink"
}

module "bucket" {
  source      = "./fabric/modules/logging-bucket"
  parent_type = "project"
  parent      = var.project_id
  id          = "${var.prefix}-bucket"
}

module "destination-project" {
  source          = "./fabric/modules/project"
  name            = "dest-prj"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "logging.googleapis.com"
  ]
}

module "project-host" {
  source          = "./fabric/modules/project"
  name            = "project"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "logging.googleapis.com"
  ]
  logging_sinks = {
    warnings = {
      destination = module.gcs.id
      filter      = "severity=WARNING"
      type        = "storage"
    }
    info = {
      destination = module.dataset.id
      filter      = "severity=INFO"
      type        = "bigquery"
    }
    notice = {
      destination = module.pubsub.id
      filter      = "severity=NOTICE"
      type        = "pubsub"
    }
    debug = {
      destination = module.bucket.id
      filter      = "severity=DEBUG"
      exclusions = {
        no-compute = "logName:compute"
      }
      type = "logging"
    }
    alert = {
      destination = module.destination-project.id
      filter      = "severity=ALERT"
      type        = "project"
    }
  }
  logging_exclusions = {
    no-gce-instances = "resource.type=gce_instance"
  }
}
# tftest modules=6 resources=19 inventory=logging.yaml e2e
```

## Data Access Logs

Activation of data access logs can be controlled via the `logging_data_access` variable. If the `iam_bindings_authoritative` variable is used to set a resource-level IAM policy, the data access log configuration will also be authoritative as part of the policy.

This example shows how to set a non-authoritative access log configuration:

```hcl
module "project" {
  source          = "./fabric/modules/project"
  name            = "project"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  prefix          = var.prefix
  logging_data_access = {
    allServices = {
      # logs for principals listed here will be excluded
      ADMIN_READ = ["group:${var.group_email}"]
    }
    "storage.googleapis.com" = {
      DATA_READ  = []
      DATA_WRITE = []
    }
  }
}
# tftest modules=1 resources=3 inventory=logging-data-access.yaml e2e
```

## Cloud KMS Encryption Keys

The module offers a simple, centralized way to assign `roles/cloudkms.cryptoKeyEncrypterDecrypter` to service identities.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  prefix          = var.prefix
  parent          = var.folder_id
  services = [
    "compute.googleapis.com",
    "storage.googleapis.com"
  ]
  service_encryption_key_ids = {
    compute = [
      var.kms_key.id
    ]
    storage = [
      var.kms_key.id
    ]
  }
}
# tftest modules=1 resources=6 e2e
```

## Attaching Tags

You can attach secure tags to a project with the `tag_bindings` attribute

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  tags = {
    environment = {
      description = "Environment specification."
      values = {
        dev  = {}
        prod = {}
      }
    }
  }
}

module "project" {
  source = "./fabric/modules/project"
  name   = "project"
  parent = var.folder_id
  tag_bindings = {
    env-prod = module.org.tag_values["environment/prod"].id
    foo      = "tagValues/12345678"
  }
}
# tftest modules=2 resources=6
```

## Project-scoped Tags

To create project-scoped secure tags, use the `tags` and `network_tags` attributes.

```hcl
module "project" {
  source = "./fabric/modules/project"
  name   = "project"
  parent = var.folder_id
  tags = {
    mytag1 = {}
    mytag2 = {
      iam = {
        "roles/resourcemanager.tagAdmin" = ["user:admin@example.com"]
      }
      values = {
        myvalue1 = {}
        myvalue2 = {
          iam = {
            "roles/resourcemanager.tagUser" = ["user:user@example.com"]
          }
        }
      }
    }
  }
  network_tags = {
    my_net_tag = {
      network = "${var.project_id}/${var.vpc.name}"
    }
  }
}
# tftest modules=1 resources=8
```

## Custom Roles

Custom roles can be defined via the `custom_roles` variable, and referenced via the `custom_role_id` output (this also provides explicit dependency on the custom role):

```hcl
module "project" {
  source = "./fabric/modules/project"
  name   = "project"
  custom_roles = {
    "myRole" = [
      "compute.instances.list",
    ]
  }
  iam = {
    (module.project.custom_role_id.myRole) = ["group:${var.group_email}"]
  }
}
# tftest modules=1 resources=3
```

### Custom Roles Factory

Custom roles can also be specified via a factory in a similar way to organization policies and policy constraints. Each file is mapped to a custom role, where

- the role name defaults to the file name but can be overridden via a `name` attribute in the yaml
- role permissions are defined in an `includedPermissions` map

Custom roles defined via the variable are merged with those coming from the factory, and override them in case of duplicate names.

```hcl
module "project" {
  source = "./fabric/modules/project"
  name   = "project"
  factories_config = {
    custom_roles = "data/custom_roles"
  }
}
# tftest modules=1 resources=3 files=custom-role-1,custom-role-2
```

```yaml
# tftest-file id=custom-role-1 path=data/custom_roles/test_1.yaml

includedPermissions:
 - compute.globalOperations.get
```

```yaml
# tftest-file id=custom-role-2 path=data/custom_roles/test_2.yaml

name: projectViewer
includedPermissions:
  - resourcemanager.projects.get
  - resourcemanager.projects.getIamPolicy
  - resourcemanager.projects.list
```

## Quotas

Project and regional quotas can be managed via the `quotas` variable. Keep in mind, that metrics returned by `gcloud compute regions describe` do not match `quota_id`s. To get a list of quotas in the project use the API call, for example to get quotas for `compute.googleapis.com` use:

```bash
curl -X GET \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://cloudquotas.googleapis.com/v1/projects/${PROJECT_ID}/locations/global/services/compute.googleapis.com/quotaInfos?pageSize=1000" \
  | grep quotaId
```

```hcl
module "project" {
  source          = "./fabric/modules/project"
  name            = "project"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  prefix          = var.prefix
  quotas = {
    cpus-ew8 = {
      service         = "compute.googleapis.com"
      quota_id        = "CPUS-per-project-region"
      contact_email   = "user@example.com"
      preferred_value = 321
      dimensions = {
        region = "europe-west8"
      }
    }
  }
  services = [
    "cloudquotas.googleapis.com",
    "compute.googleapis.com"
  ]
}
# tftest modules=1 resources=4 inventory=quotas.yaml e2e
```

## Quotas factory

Quotas can be also specified via a factory in a similar way to organization policies, policy constraints and custom roles by pointing to a directory containing YAML files where each file defines one or more quotas. The structure of the YAML files is exactly the same as the `quotas` variable.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  name            = "project"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  prefix          = var.prefix
  factories_config = {
    quotas = "data/quotas"
  }
  services = [
    "cloudquotas.googleapis.com",
    "compute.googleapis.com"
  ]
}
# tftest modules=1 resources=4 files=quota-cpus-ew8 inventory=quotas.yaml e2e
```

```yaml
# tftest-file id=quota-cpus-ew8 path=data/quotas/cpus-ew8.yaml

---
# Terraform will be unable to decode this file if it does not contain valid YAML
# You can retain `---` (start of the document) to indicate an empty document.

cpus-ew8:
  service: compute.googleapis.com
  quota_id: CPUS-per-project-region
  contact_email: user@example.com
  preferred_value: 321
  dimensions:
    region: europe-west8
```

## VPC Service Controls

This module also allows managing project membership in VPC Service Controls perimeters. When using this functionality care should be taken so that perimeter management (e.g. via the `vpc-sc` module) does not try reconciling resources, to avoid permadiffs and related violations.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  vpc_sc = {
    perimeter_name = "accessPolicies/1234567890/servicePerimeters/default"
  }
}
# tftest modules=1 resources=4 inventory=vpc-sc.yaml
```

Perimeter bridges and dry run configuration are also supported.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  services = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  vpc_sc = {
    perimeter_name = "accessPolicies/1234567890/servicePerimeters/default"
    perimeter_bridges = [
      "accessPolicies/1234567890/servicePerimeters/b1",
      "accessPolicies/1234567890/servicePerimeters/b2",
    ]
    is_dry_run = true
  }
}
# tftest modules=1 resources=6
```

## Outputs

Most of this module's outputs depend on its resources, to allow Terraform to compute all dependencies required for the project to be correctly configured. This allows you to reference outputs like `project_id` in other modules or resources without having to worry about setting `depends_on` blocks manually.

One non-obvious output is `service_accounts`, which offers a simple way to discover service identities and default service accounts, and guarantees that service identities that require an API call to trigger creation (like GCS or BigQuery) exist before use.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  prefix          = var.prefix
  parent          = var.folder_id
  services = [
    "compute.googleapis.com"
  ]
}

output "compute_robot" {
  value = module.project.service_accounts.robots.compute
}
# tftest modules=1 resources=2 inventory=outputs.yaml e2e
```

### Managing project related configuration without creating it

The module offers managing all related resources without ever touching the project itself by using `project_create = false`

```hcl
module "create-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
}

module "project" {
  source          = "./fabric/modules/project"
  depends_on      = [module.create-project]
  billing_account = var.billing_account_id
  name            = "project"
  parent          = var.folder_id
  prefix          = var.prefix
  project_create  = false

  iam_by_principals = {
    "group:${var.group_email}" = [
      "roles/cloudasset.owner",
      "roles/cloudsupport.techSupportEditor",
      "roles/iam.securityReviewer",
      "roles/logging.admin",
    ]
  }
  iam_bindings = {
    iam_admin_conditional = {
      members = [
        "group:${var.group_email}"
      ]
      role = "roles/resourcemanager.projectIamAdmin"
      condition = {
        title      = "delegated_network_user_one"
        expression = <<-END
          api.getAttribute(
            'iam.googleapis.com/modifiedGrantsByRole', []
          ).hasOnly([
            'roles/compute.networkAdmin'
          ])
        END
      }
    }
  }
  iam_bindings_additive = {
    group-owner = {
      member = "group:${var.group_email}"
      role   = "roles/owner"
    }
  }
  iam = {
    "roles/editor" = [
      "serviceAccount:${module.project.service_accounts.cloud_services}"
    ]
    "roles/apigee.serviceAgent" = [
      "serviceAccount:${module.project.service_accounts.robots.apigee}"
    ]
  }
  logging_data_access = {
    allServices = {
      # logs for principals listed here will be excluded
      ADMIN_READ = ["group:${var.group_email}"]
    }
    "storage.googleapis.com" = {
      DATA_READ  = []
      DATA_WRITE = []
    }
  }
  logging_sinks = {
    warnings = {
      destination = module.gcs.id
      filter      = "severity=WARNING"
      type        = "storage"
    }
    info = {
      destination = module.dataset.id
      filter      = "severity=INFO"
      type        = "bigquery"
    }
    notice = {
      destination = module.pubsub.id
      filter      = "severity=NOTICE"
      type        = "pubsub"
    }
    debug = {
      destination = module.bucket.id
      filter      = "severity=DEBUG"
      exclusions = {
        no-compute = "logName:compute"
      }
      type = "logging"
    }
  }
  logging_exclusions = {
    no-gce-instances = "resource.type=gce_instance"
  }
  org_policies = {
    "compute.disableGuestAttributesAccess" = {
      rules = [{ enforce = true }]
    }
    "compute.skipDefaultNetworkCreation" = {
      rules = [{ enforce = true }]
    }
    "iam.disableServiceAccountKeyCreation" = {
      rules = [{ enforce = true }]
    }
    "iam.disableServiceAccountKeyUpload" = {
      rules = [
        {
          condition = {
            expression  = "resource.matchTagId('tagKeys/1234', 'tagValues/1234')"
            title       = "condition"
            description = "test condition"
            location    = "somewhere"
          }
          enforce = true
        },
        {
          enforce = false
        }
      ]
    }
    "iam.allowedPolicyMemberDomains" = {
      rules = [{
        allow = {
          values = ["C0xxxxxxx", "C0yyyyyyy"]
        }
      }]
    }
    "compute.trustedImageProjects" = {
      rules = [{
        allow = {
          values = ["projects/my-project"]
        }
      }]
    }
    "compute.vmExternalIpAccess" = {
      rules = [{ deny = { all = true } }]
    }
  }
  shared_vpc_service_config = {
    host_project       = module.host-project.project_id
    service_iam_grants = module.project.services
    service_identity_iam = {
      "roles/cloudasset.owner" = [
        "cloudservices", "container-engine"
      ]
    }
  }
  services = [
    "apigee.googleapis.com",
    "bigquery.googleapis.com",
    "container.googleapis.com",
    "logging.googleapis.com",
    "run.googleapis.com",
    "storage.googleapis.com",
  ]
  service_encryption_key_ids = {
    compute = [
      var.kms_key.id
    ]
    storage = [
      var.kms_key.id
    ]
  }
}

module "host-project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  name            = "host"
  parent          = var.folder_id
  prefix          = var.prefix
  shared_vpc_host_config = {
    enabled = true
  }
}

module "gcs" {
  source        = "./fabric/modules/gcs"
  project_id    = var.project_id
  name          = "gcs_sink"
  prefix        = var.prefix
  force_destroy = true
}

module "dataset" {
  source     = "./fabric/modules/bigquery-dataset"
  project_id = var.project_id
  id         = "bq_sink"
  options    = { delete_contents_on_destroy = true }
}

module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "pubsub_sink"
}

module "bucket" {
  source      = "./fabric/modules/logging-bucket"
  parent_type = "project"
  parent      = var.project_id
  id          = "${var.prefix}-bucket"
}
# tftest modules=7 resources=53 inventory=data.yaml e2e
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | resources |
|---|---|---|
| [iam.tf](./iam.tf) | IAM bindings. | <code>google_project_iam_binding</code> · <code>google_project_iam_custom_role</code> · <code>google_project_iam_member</code> |
| [logging.tf](./logging.tf) | Log sinks and supporting resources. | <code>google_bigquery_dataset_iam_member</code> · <code>google_logging_project_exclusion</code> · <code>google_logging_project_sink</code> · <code>google_project_iam_audit_config</code> · <code>google_project_iam_member</code> · <code>google_pubsub_topic_iam_member</code> · <code>google_storage_bucket_iam_member</code> |
| [main.tf](./main.tf) | Module-level locals and resources. | <code>google_compute_project_metadata_item</code> · <code>google_essential_contacts_contact</code> · <code>google_monitoring_monitored_project</code> · <code>google_project</code> · <code>google_project_service</code> · <code>google_resource_manager_lien</code> |
| [organization-policies.tf](./organization-policies.tf) | Project-level organization policies. | <code>google_org_policy_policy</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [quotas.tf](./quotas.tf) | None | <code>google_cloud_quotas_quota_preference</code> |
| [service-accounts.tf](./service-accounts.tf) | Service identities and supporting resources. | <code>google_kms_crypto_key_iam_member</code> · <code>google_project_default_service_accounts</code> · <code>google_project_iam_member</code> · <code>google_project_service_identity</code> |
| [shared-vpc.tf](./shared-vpc.tf) | Shared VPC project-level configuration. | <code>google_compute_shared_vpc_host_project</code> · <code>google_compute_shared_vpc_service_project</code> · <code>google_compute_subnetwork_iam_member</code> · <code>google_project_iam_member</code> |
| [tags.tf](./tags.tf) | None | <code>google_tags_tag_binding</code> · <code>google_tags_tag_key</code> · <code>google_tags_tag_key_iam_binding</code> · <code>google_tags_tag_value</code> · <code>google_tags_tag_value_iam_binding</code> |
| [variables-iam.tf](./variables-iam.tf) | None |  |
| [variables-quotas.tf](./variables-quotas.tf) | None |  |
| [variables-tags.tf](./variables-tags.tf) | None |  |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |
| [vpc-sc.tf](./vpc-sc.tf) | VPC-SC project-level perimeter configuration. | <code>google_access_context_manager_service_perimeter_dry_run_resource</code> · <code>google_access_context_manager_service_perimeter_resource</code> |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L153) | Project name and id suffix. | <code>string</code> | ✓ |  |
| [auto_create_network](variables.tf#L17) | Whether to create the default network for the project. | <code>bool</code> |  | <code>false</code> |
| [billing_account](variables.tf#L23) | Billing account id. | <code>string</code> |  | <code>null</code> |
| [compute_metadata](variables.tf#L29) | Optional compute metadata key/values. Only usable if compute API has been enabled. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [contacts](variables.tf#L36) | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT_UPDATES. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [custom_roles](variables.tf#L43) | Map of role name => list of permissions to create in this project. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [default_service_account](variables.tf#L50) | Project default service account setting: can be one of `delete`, `deprivilege`, `disable`, or `keep`. | <code>string</code> |  | <code>&#34;keep&#34;</code> |
| [descriptive_name](variables.tf#L63) | Name of the project name. Used for project name instead of `name` variable. | <code>string</code> |  | <code>null</code> |
| [factories_config](variables.tf#L69) | Paths to data files and folders that enable factory functionality. | <code title="object&#40;&#123;&#10;  custom_roles &#61; optional&#40;string&#41;&#10;  org_policies &#61; optional&#40;string&#41;&#10;  quotas       &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables-iam.tf#L17) | Authoritative IAM bindings in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings](variables-iam.tf#L24) | Authoritative IAM bindings in {KEY => {role = ROLE, members = [], condition = {}}}. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  members &#61; list&#40;string&#41;&#10;  role    &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_bindings_additive](variables-iam.tf#L39) | Individual additive IAM bindings. Keys are arbitrary. | <code title="map&#40;object&#40;&#123;&#10;  member &#61; string&#10;  role   &#61; string&#10;  condition &#61; optional&#40;object&#40;&#123;&#10;    expression  &#61; string&#10;    title       &#61; string&#10;    description &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam_by_principals](variables-iam.tf#L54) | Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L80) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [lien_reason](variables.tf#L87) | If non-empty, creates a project lien with this description. | <code>string</code> |  | <code>null</code> |
| [logging_data_access](variables.tf#L93) | Control activation of data access logs. Format is service => { log type => [exempted members]}. The special 'allServices' key denotes configuration for all services. | <code>map&#40;map&#40;list&#40;string&#41;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_exclusions](variables.tf#L108) | Logging exclusions for this project in the form {NAME -> FILTER}. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [logging_sinks](variables.tf#L115) | Logging sinks to create for this project. | <code title="map&#40;object&#40;&#123;&#10;  bq_partitioned_table &#61; optional&#40;bool, false&#41;&#10;  description          &#61; optional&#40;string&#41;&#10;  destination          &#61; string&#10;  disabled             &#61; optional&#40;bool, false&#41;&#10;  exclusions           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  filter               &#61; optional&#40;string&#41;&#10;  iam                  &#61; optional&#40;bool, true&#41;&#10;  type                 &#61; string&#10;  unique_writer        &#61; optional&#40;bool, true&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [metric_scopes](variables.tf#L146) | List of projects that will act as metric scopes for this project. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [network_tags](variables-tags.tf#L17) | Network tags by key name. If `id` is provided, key creation is skipped. The `iam` attribute behaves like the similarly named one at module level. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Managed by the Terraform project module.&#34;&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  id          &#61; optional&#40;string&#41;&#10;  network     &#61; string &#35; project_id&#47;vpc_name&#10;  values &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; optional&#40;string, &#34;Managed by the Terraform project module.&#34;&#41;&#10;    iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [org_policies](variables.tf#L158) | Organization policies applied to this project keyed by policy name. | <code title="map&#40;object&#40;&#123;&#10;  inherit_from_parent &#61; optional&#40;bool&#41; &#35; for list policies only.&#10;  reset               &#61; optional&#40;bool&#41;&#10;  rules &#61; optional&#40;list&#40;object&#40;&#123;&#10;    allow &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    deny &#61; optional&#40;object&#40;&#123;&#10;      all    &#61; optional&#40;bool&#41;&#10;      values &#61; optional&#40;list&#40;string&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    enforce &#61; optional&#40;bool&#41; &#35; for boolean policies only.&#10;    condition &#61; optional&#40;object&#40;&#123;&#10;      description &#61; optional&#40;string&#41;&#10;      expression  &#61; optional&#40;string&#41;&#10;      location    &#61; optional&#40;string&#41;&#10;      title       &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#41;, &#91;&#93;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [parent](variables.tf#L185) | Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format. | <code>string</code> |  | <code>null</code> |
| [prefix](variables.tf#L195) | Optional prefix used to generate project id and name. | <code>string</code> |  | <code>null</code> |
| [project_create](variables.tf#L205) | Create project. When set to false, uses a data source to reference existing project. | <code>bool</code> |  | <code>true</code> |
| [quotas](variables-quotas.tf#L17) | Service quota configuration. | <code title="map&#40;object&#40;&#123;&#10;  service              &#61; string&#10;  quota_id             &#61; string&#10;  preferred_value      &#61; number&#10;  dimensions           &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  justification        &#61; optional&#40;string&#41;&#10;  contact_email        &#61; optional&#40;string&#41;&#10;  annotations          &#61; optional&#40;map&#40;string&#41;&#41;&#10;  ignore_safety_checks &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_config](variables.tf#L211) | Configure service API activation. | <code title="object&#40;&#123;&#10;  disable_on_destroy         &#61; bool&#10;  disable_dependent_services &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  disable_on_destroy         &#61; false&#10;  disable_dependent_services &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |
| [service_encryption_key_ids](variables.tf#L223) | Cloud KMS encryption key in {SERVICE => [KEY_URL]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [services](variables.tf#L229) | Service APIs to enable. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [shared_vpc_host_config](variables.tf#L235) | Configures this project as a Shared VPC host project (mutually exclusive with shared_vpc_service_project). | <code title="object&#40;&#123;&#10;  enabled          &#61; bool&#10;  service_projects &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [shared_vpc_service_config](variables.tf#L244) | Configures this project as a Shared VPC service project (mutually exclusive with shared_vpc_host_config). | <code title="object&#40;&#123;&#10;  host_project                &#61; string&#10;  network_users               &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  service_identity_iam        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  service_identity_subnet_iam &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  service_iam_grants          &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  network_subnet_users        &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  host_project &#61; null&#10;&#125;">&#123;&#8230;&#125;</code> |
| [skip_delete](variables.tf#L272) | Allows the underlying resources to be destroyed without destroying the project itself. | <code>bool</code> |  | <code>false</code> |
| [tag_bindings](variables-tags.tf#L45) | Tag bindings for this project, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>null</code> |
| [tags](variables-tags.tf#L51) | Tags by key name. If `id` is provided, key or value creation is skipped. The `iam` attribute behaves like the similarly named one at module level. | <code title="map&#40;object&#40;&#123;&#10;  description &#61; optional&#40;string, &#34;Managed by the Terraform project module.&#34;&#41;&#10;  iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;  id          &#61; optional&#40;string&#41;&#10;  values &#61; optional&#40;map&#40;object&#40;&#123;&#10;    description &#61; optional&#40;string, &#34;Managed by the Terraform project module.&#34;&#41;&#10;    iam         &#61; optional&#40;map&#40;list&#40;string&#41;&#41;, &#123;&#125;&#41;&#10;    id          &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vpc_sc](variables.tf#L278) | VPC-SC configuration for the project, use when `ignore_changes` for resources is set in the VPC-SC module. | <code title="object&#40;&#123;&#10;  perimeter_name    &#61; string&#10;  perimeter_bridges &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  is_dry_run        &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [custom_role_id](outputs.tf#L17) | Map of custom role IDs created in the project. |  |
| [custom_roles](outputs.tf#L27) | Map of custom roles resources created in the project. |  |
| [id](outputs.tf#L32) | Project id. |  |
| [name](outputs.tf#L51) | Project name. |  |
| [number](outputs.tf#L63) | Project number. |  |
| [project_id](outputs.tf#L82) | Project id. |  |
| [quota_configs](outputs.tf#L101) | Quota configurations. |  |
| [quotas](outputs.tf#L112) | Quota resources. |  |
| [service_accounts](outputs.tf#L117) | Product robot service accounts in project. |  |
| [services](outputs.tf#L133) | Service APIs to enabled in the project. |  |
| [sink_writer_identities](outputs.tf#L142) | Writer identities created for each sink. |  |
| [tag_keys](outputs.tf#L149) | Tag key resources. |  |
| [tag_values](outputs.tf#L158) | Tag value resources. |  |
<!-- END TFDOC -->
