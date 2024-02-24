# Cloud Run Module

Cloud Run Services and Jobs, with support for IAM roles and Eventarc trigger creation.

<!-- BEGIN TOC -->
- [Examples](#examples)
  - [IAM and environment variables](#iam-and-environment-variables)
  - [Mounting secrets as volumes](#mounting-secrets-as-volumes)
  - [Beta features](#beta-features)
  - [VPC Access Connector](#vpc-access-connector)
  - [Eventarc triggers](#eventarc-triggers)
    - [PubSub](#pubsub)
    - [Audit logs](#audit-logs)
    - [Using custom service accounts for triggers](#using-custom-service-accounts-for-triggers)
  - [Cloud Run Service Account](#cloud-run-service-account)
  - [Creating Cloud Run Jobs](#creating-cloud-run-jobs)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

## Examples

### IAM and environment variables

IAM bindings support the usual syntax. Container environment values can be declared as key-value strings or as references to Secret Manager secrets. Both can be combined as long as there is no duplication of keys:

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = "hello"
  region     = var.region
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      env = {
        VAR1 = "VALUE1"
        VAR2 = "VALUE2"
      }
      env_from_key = {
        SECRET1 = {
          secret  = module.secret-manager.secrets["credentials"].name
          version = module.secret-manager.version_versions["credentials:v1"]
        }
      }
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
}
# tftest modules=2 resources=5 fixtures=fixtures/secret-credentials.tf inventory=service-iam-env.yaml e2e
```

### Mounting secrets as volumes

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = "hello"
  region     = var.region
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      volume_mounts = {
        "credentials" = "/credentials"
      }
    }
  }
  volumes = {
    credentials = {
      secret = {
        name    = module.secret-manager.secrets["credentials"].id
        path    = "my-secret"
        version = "latest" # TODO: should be optional, but results in API error
      }
    }
  }
}
# tftest modules=2 resources=4 fixtures=fixtures/secret-credentials.tf inventory=service-volume-secretes.yaml e2e
```

### Beta features

To use beta features like Direct VPC Egress, set the launch stage to a preview stage.

```hcl
module "cloud_run" {
  source       = "./fabric/modules/cloud-run-v2"
  project_id   = var.project_id
  name         = "hello"
  region       = var.region
  launch_stage = "BETA"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  revision = {
    gen2_execution_environment = true
    max_instance_count         = 20
    vpc_access = {
      egress = "ALL_TRAFFIC"
      subnet = "default"
      tags   = ["tag1", "tag2", "tag3"]
    }
  }
}
# tftest modules=1 resources=1 inventory=service-beta-features.yaml
```

### VPC Access Connector

You can use an existing [VPC Access Connector](https://cloud.google.com/vpc/docs/serverless-vpc-access) to connect to a VPC from Cloud Run.

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  revision = {
    vpc_access = {
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC"
    }
  }
}
# tftest modules=1 resources=2 fixtures=fixtures/vpc-connector.tf inventory=service-vpc-access-connector.yaml e2e
```

If creation of the VPC Access Connector is required, use the `vpc_connector_create` variable which also supports optional attributes like number of instances, machine type, or throughput. The connector will be used automatically.

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  vpc_connector_create = {
    ip_cidr_range = "10.10.10.0/28"
    network       = var.vpc.self_link
    instances = {
      max = 10
      min = 2
    }
  }
}
# tftest modules=1 resources=2 inventory=service-vpc-access-connector-create.yaml e2e
```

Note that if you are using a Shared VPC for the connector, you need to specify a subnet and the host project if this is not where the Cloud Run service is deployed.

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = module.project-service.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  vpc_connector_create = {
    machine_type = "e2-standard-4"
    subnet = {
      name       = module.net-vpc-host.subnets["${var.region}/fixture-subnet-28"].name
      project_id = module.project-host.project_id
    }
  }
}
# tftest modules=4 resources=40 fixtures=fixtures/shared-vpc.tf inventory=service-vpc-access-connector-create-sharedvpc.yaml e2e
```

### Eventarc triggers

#### PubSub

This deploys a Cloud Run service that will be triggered when messages are published to Pub/Sub topics.

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  eventarc_triggers = {
    pubsub = {
      topic-1 = module.pubsub.topic.name
    }
  }
}
# tftest modules=2 resources=4 fixtures=fixtures/pubsub.tf inventory=service-eventarc-pubsub.yaml e2e
```

#### Audit logs

This deploys a Cloud Run service that will be triggered when specific log events are written to Google Cloud audit logs.

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  eventarc_triggers = {
    audit_log = {
      setiampolicy = {
        method  = "SetIamPolicy"
        service = "cloudresourcemanager.googleapis.com"
      }
    }
    service_account_create = true
  }
}
# tftest modules=1 resources=4 inventory=service-eventarc-auditlogs-sa-create.yaml
```

#### Using custom service accounts for triggers

By default `Compute default service account` is used to trigger Cloud Run. If you want to use custom Service Accounts you can either provide your own in `eventarc_triggers.service_account_email` or set `eventarc_triggers.service_account_create` to true and service account named `tf-cr-trigger-${var.name}` will be created with `roles/run.invoker` granted on this Cloud Run service.

Example using provided service account:

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  eventarc_triggers = {
    audit_log = {
      setiampolicy = {
        method  = "SetIamPolicy"
        service = "cloudresourcemanager.googleapis.com"
      }
    }
    service_account_email = "cloud-run-trigger@my-project.iam.gserviceaccount.com"
  }
}
# tftest modules=1 resources=2 inventory=service-eventarc-auditlogs-external-sa.yaml
```

Example using automatically created service account:

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  eventarc_triggers = {
    pubsub = {
      topic-1 = module.pubsub.topic.name
    }
    service_account_create = true
  }
}
# tftest modules=2 resources=6 fixtures=fixtures/pubsub.tf inventory=service-eventarc-pubsub-sa-create.yaml e2e
```

### Cloud Run Service Account

To use a custom service account managed by the module, set `service_account_create` to `true` and leave `service_account` set to `null` (default).

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  service_account_create = true
}
# tftest modules=1 resources=2 inventory=service-sa-create.yaml e2e
```

To use an externally managed service account, use its email in `service_account` and leave `service_account_create` to `false` (default).

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  service_account = module.iam-service-account.email
}
# tftest modules=2 resources=2 fixtures=fixtures/iam-service-account.tf inventory=service-external-sa.yaml e2e
```

### Creating Cloud Run Jobs
To create a job instead of service set `create_job` to `true`. Jobs support all functions above apart from triggers.

Unsupported variables / attributes:
* ingress
* revision.gen2_execution_environment (they run by default in gen2)
* revision.name
* containers.liveness_probe
* containers.startup_probe
* containers.resources.cpu_idle
* containers.resources.startup_cpu_boost

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = "hello"
  region     = var.region
  create_job = true
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      env = {
        VAR1 = "VALUE1"
        VAR2 = "VALUE2"
      }
    }
  }
  iam = {
    "roles/run.invoker" = ["group:${var.group_email}"]
  }
}

# tftest modules=1 resources=2 inventory=job-iam-env.yaml e2e
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L147) | Name used for Cloud Run service. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L162) | Project id used for all resources. | <code>string</code> | ✓ |  |
| [region](variables.tf#L167) | Region used for all resources. | <code>string</code> | ✓ |  |
| [containers](variables.tf#L17) | Containers in name => attributes format. | <code title="map&#40;object&#40;&#123;&#10;  image   &#61; string&#10;  command &#61; optional&#40;list&#40;string&#41;&#41;&#10;  args    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  env     &#61; optional&#40;map&#40;string&#41;&#41;&#10;  env_from_key &#61; optional&#40;map&#40;object&#40;&#123;&#10;    secret  &#61; string&#10;    version &#61; string&#10;  &#125;&#41;&#41;&#41;&#10;  liveness_probe &#61; optional&#40;object&#40;&#123;&#10;    grpc &#61; optional&#40;object&#40;&#123;&#10;      port    &#61; optional&#40;number&#41;&#10;      service &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    http_get &#61; optional&#40;object&#40;&#123;&#10;      http_headers &#61; optional&#40;map&#40;string&#41;&#41;&#10;      path         &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    failure_threshold     &#61; optional&#40;number&#41;&#10;    initial_delay_seconds &#61; optional&#40;number&#41;&#10;    period_seconds        &#61; optional&#40;number&#41;&#10;    timeout_seconds       &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  ports &#61; optional&#40;map&#40;object&#40;&#123;&#10;    container_port &#61; optional&#40;number&#41;&#10;    name           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  resources &#61; optional&#40;object&#40;&#123;&#10;    limits &#61; optional&#40;object&#40;&#123;&#10;      cpu    &#61; string&#10;      memory &#61; string&#10;    &#125;&#41;&#41;&#10;    cpu_idle          &#61; optional&#40;bool&#41;&#10;    startup_cpu_boost &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  startup_probe &#61; optional&#40;object&#40;&#123;&#10;    grpc &#61; optional&#40;object&#40;&#123;&#10;      port    &#61; optional&#40;number&#41;&#10;      service &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    http_get &#61; optional&#40;object&#40;&#123;&#10;      http_headers &#61; optional&#40;map&#40;string&#41;&#41;&#10;      path         &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    tcp_socket &#61; optional&#40;object&#40;&#123;&#10;      port &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    failure_threshold     &#61; optional&#40;number&#41;&#10;    initial_delay_seconds &#61; optional&#40;number&#41;&#10;    period_seconds        &#61; optional&#40;number&#41;&#10;    timeout_seconds       &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  volume_mounts &#61; optional&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [create_job](variables.tf#L77) | Create Cloud Run Job instead of Service. | <code>bool</code> |  | <code>false</code> |
| [eventarc_triggers](variables.tf#L83) | Event arc triggers for different sources. | <code title="object&#40;&#123;&#10;  audit_log &#61; optional&#40;map&#40;object&#40;&#123;&#10;    method  &#61; string&#10;    service &#61; string&#10;  &#125;&#41;&#41;&#41;&#10;  pubsub                 &#61; optional&#40;map&#40;string&#41;&#41;&#10;  service_account_email  &#61; optional&#40;string&#41;&#10;  service_account_create &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L101) | IAM bindings for Cloud Run service in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ingress](variables.tf#L107) | Ingress settings. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L124) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [launch_stage](variables.tf#L130) | The launch stage as defined by Google Cloud Platform Launch Stages. | <code>string</code> |  | <code>null</code> |
| [prefix](variables.tf#L152) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [revision](variables.tf#L172) | Revision template configurations. | <code title="object&#40;&#123;&#10;  name                       &#61; optional&#40;string&#41;&#10;  gen2_execution_environment &#61; optional&#40;bool&#41;&#10;  max_concurrency            &#61; optional&#40;number&#41;&#10;  max_instance_count         &#61; optional&#40;number&#41;&#10;  min_instance_count         &#61; optional&#40;number&#41;&#10;  vpc_access &#61; optional&#40;object&#40;&#123;&#10;    connector &#61; optional&#40;string&#41;&#10;    egress    &#61; optional&#40;string&#41;&#10;    subnet    &#61; optional&#40;string&#41;&#10;    tags      &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  timeout &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_account](variables.tf#L199) | Service account email. Unused if service account is auto-created. | <code>string</code> |  | <code>null</code> |
| [service_account_create](variables.tf#L205) | Auto-create service account. | <code>bool</code> |  | <code>false</code> |
| [volumes](variables.tf#L211) | Named volumes in containers in name => attributes format. | <code title="map&#40;object&#40;&#123;&#10;  secret &#61; optional&#40;object&#40;&#123;&#10;    name         &#61; string&#10;    default_mode &#61; optional&#40;string&#41;&#10;    path         &#61; optional&#40;string&#41;&#10;    version      &#61; optional&#40;string&#41;&#10;    mode         &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  cloud_sql_instances &#61; optional&#40;list&#40;string&#41;&#41;&#10;  empty_dir_size      &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vpc_connector_create](variables-vpcconnector.tf#L17) | Populate this to create a Serverless VPC Access connector. | <code title="object&#40;&#123;&#10;  ip_cidr_range &#61; optional&#40;string&#41;&#10;  machine_type  &#61; optional&#40;string&#41;&#10;  name          &#61; optional&#40;string&#41;&#10;  network       &#61; optional&#40;string&#41;&#10;  instances &#61; optional&#40;object&#40;&#123;&#10;    max &#61; optional&#40;number&#41;&#10;    min &#61; optional&#40;number&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  throughput &#61; optional&#40;object&#40;&#123;&#10;    max &#61; optional&#40;number, 1000&#41; &#35; workaround for a wrong default in provider&#10;    min &#61; optional&#40;number&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  subnet &#61; optional&#40;object&#40;&#123;&#10;    name       &#61; optional&#40;string&#41;&#10;    project_id &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified job or service id. |  |
| [job](outputs.tf#L22) | Cloud Run Job. |  |
| [service](outputs.tf#L27) | Cloud Run Service. |  |
| [service_account](outputs.tf#L32) | Service account resource. |  |
| [service_account_email](outputs.tf#L37) | Service account email. |  |
| [service_account_iam_email](outputs.tf#L42) | Service account email. |  |
| [service_name](outputs.tf#L50) | Cloud Run service name. |  |
| [vpc_connector](outputs.tf#L55) | VPC connector resource if created. |  |

## Fixtures

- [iam-service-account.tf](../../tests/fixtures/iam-service-account.tf)
- [pubsub.tf](../../tests/fixtures/pubsub.tf)
- [secret-credentials.tf](../../tests/fixtures/secret-credentials.tf)
- [shared-vpc.tf](../../tests/fixtures/shared-vpc.tf)
- [vpc-connector.tf](../../tests/fixtures/vpc-connector.tf)
<!-- END TFDOC -->
