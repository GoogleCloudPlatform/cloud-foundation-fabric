# Cloud Run Module

Cloud Run management, with support for IAM roles, revision annotations and optional Eventarc trigger creation.

<!-- BEGIN TOC -->
- [IAM and environment variables](#iam-and-environment-variables)
- [Mounting secrets as volumes](#mounting-secrets-as-volumes)
- [Revision annotations](#revision-annotations)
- [Second generation execution environment](#second-generation-execution-environment)
- [VPC Access Connector creation](#vpc-access-connector-creation)
- [Traffic split](#traffic-split)
- [Eventarc triggers](#eventarc-triggers)
  - [PubSub](#pubsub)
  - [Audit logs](#audit-logs)
  - [Using custom service accounts for triggers](#using-custom-service-accounts-for-triggers)
- [Service account](#service-account)
- [Tag bindings](#tag-bindings)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## IAM and environment variables

IAM bindings support the usual syntax. Container environment values can be declared as key-value strings or as references to Secret Manager secrets. Both can be combined as long as there's no duplication of keys:

```hcl

module "secret-manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = var.project_id
  secrets = {
    credentials = {}
  }
  iam = {
    credentials = {
      "roles/secretmanager.secretAccessor" = [module.cloud_run.service_account_iam_email]
    }
  }
}

module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      env = {
        VAR1 = "VALUE1"
        VAR2 = "VALUE2"
      }
      env_from = {
        SECRET1 = {
          name = module.secret-manager.ids["credentials"]
          key  = "latest"
        }
      }
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  service_account_create = true
}
# tftest modules=2 resources=5 inventory=simple.yaml e2e
```

## Mounting secrets as volumes

```hcl
module "secret-manager" {
  source     = "./fabric/modules/secret-manager"
  project_id = var.project_id
  secrets = {
    credentials = {}
  }
  versions = {
    credentials = {
      v1 = { enabled = true, data = "foo bar baz" }
    }
  }
  iam = {
    credentials = {
      "roles/secretmanager.secretAccessor" = [module.cloud_run.service_account_iam_email]
    }
  }
}


module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
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
  service_account_create = true
  volumes = {
    credentials = {
      name        = module.secret-manager.secrets["credentials"].name
      secret_name = "credentials" # TODO: module.secret-manager.secrets["credentials"].name
      items = {
        latest = { path = "v1.txt" }
      }
    }
  }
}
# tftest modules=2 resources=5 inventory=secrets.yaml e2e
```

## Revision annotations

Annotations can be specified via the `revision_annotations` variable:

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  revision_annotations = {
    autoscaling = {
      max_scale = 10
      min_scale = 1
    }
    cloudsql_unstances  = ["sql-0", "sql-1"]
    vpcaccess_connector = "foo"
    vpcaccess_egress    = "all-traffic"
  }
}
# tftest modules=1 resources=1 inventory=revision-annotations.yaml
```

## Second generation execution environment

Second generation execution environment (gen2) can be enabled by setting the `gen2_execution_environment` variable to true:

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  gen2_execution_environment = true
}
# tftest modules=1 resources=1 inventory=gen2.yaml e2e
```

## VPC Access Connector creation

If creation of a [VPC Access Connector](https://cloud.google.com/vpc/docs/serverless-vpc-access) is required, use the `vpc_connector_create` variable which also support optional attributes for number of instances, machine type, and throughput (not shown here). The annotation to use the connector will be added automatically.

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
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
    throughput = {
      max = 300
      min = 200
    }
    vpc_self_link = var.vpc.self_link
  }
}
# tftest modules=1 resources=2 inventory=connector.yaml e2e
```

Note that if you are using Shared VPC you need to specify a subnet:

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  vpc_connector_create = {
    subnet = {
      name       = "subnet-vpc-access"
      project_id = "host-project"
    }
  }
}
# tftest modules=1 resources=2 inventory=connector-shared.yaml
```

## Traffic split

This deploys a Cloud Run service with traffic split between two revisions.

```hcl
module "cloud_run" {
  source        = "./fabric/modules/cloud-run"
  project_id    = var.project_id
  region        = var.region
  name          = "hello"
  revision_name = "green"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  traffic = {
    blue  = { percent = 25 }
    green = { percent = 75 }
  }
}
# tftest modules=1 resources=1 inventory=traffic.yaml
```

## Eventarc triggers

### PubSub

This deploys a Cloud Run service that will be triggered when messages are published to Pub/Sub topics.

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "pubsub_sink"
}

module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
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
      topic-1 = module.pubsub.id
    }
  }
}
# tftest modules=2 resources=3 inventory=eventarc.yaml e2e
```

### Audit logs

This deploys a Cloud Run service that will be triggered when specific log events are written to Google Cloud audit logs.

```hcl
module "sa" {
  source     = "./fabric/modules/iam-service-account"
  project_id = var.project_id
  name       = "eventarc-trigger"
  iam_project_roles = {
    (var.project_id) = ["roles/eventarc.eventReceiver"]
  }
}

module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
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
    service_account_email = module.sa.email
  }
  iam = {
    "roles/run.invoker" = [module.sa.iam_email]
  }
}
# tftest modules=2 resources=5 inventory=audit-logs.yaml
```

### Using custom service accounts for triggers

By default `Compute default service account` is used to trigger Cloud Run. If you want to use custom Service Account you can either provide your own in `eventarc_triggers.service_account_email` or set `eventarc_triggers.service_account_create` to true and service account named `tf-cr-trigger-${var.name}` will be created with `roles/run.invoker` granted on this Cloud Run service.

For example using provided service account refer to [Audit logs](#audit-logs) example.

Example using automatically created service account:

```hcl
module "pubsub" {
  source     = "./fabric/modules/pubsub"
  project_id = var.project_id
  name       = "pubsub_sink"
}

module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
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
      topic-1 = module.pubsub.id
    }
    service_account_create = true
  }
}
# tftest modules=2 resources=5 inventory=trigger-service-account.yaml e2e
```

## Service account

To use a custom service account managed by the module, set `service_account_create` to `true` and leave `service_account` set to `null` value (default).

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
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
# tftest modules=1 resources=2 inventory=service-account.yaml e2e
```

To use an externally managed service account, pass its email in `service_account` and leave `service_account_create` to `false` (the default).

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  service_account = var.service_account.email
}
# tftest modules=1 resources=1 inventory=service-account-external.yaml e2e
```

## Tag bindings

Refer to the [Creating and managing tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) documentation for details on usage.

```hcl
module "org" {
  source          = "./fabric/modules/organization"
  organization_id = var.organization_id
  tags = {
    environment = {
      description = "Environment specification."
      values = {
        dev     = {}
        prod    = {}
        sandbox = {}
      }
    }
  }
}

module "cloud_run" {
  source     = "./fabric/modules/cloud-run"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  tag_bindings = {
    env-sandbox = module.org.tag_values["environment/sandbox"].id
  }
}
# tftest modules=2 resources=6
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L144) | Name used for cloud run service. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L159) | Project id used for all resources. | <code>string</code> | ✓ |  |
| [region](variables.tf#L164) | Region used for all resources. | <code>string</code> | ✓ |  |
| [container_concurrency](variables.tf#L18) | Maximum allowed in-flight (concurrent) requests per container of the revision. | <code>string</code> |  | <code>null</code> |
| [containers](variables.tf#L24) | Containers in arbitrary key => attributes format. | <code title="map&#40;object&#40;&#123;&#10;  image   &#61; string&#10;  args    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  command &#61; optional&#40;list&#40;string&#41;&#41;&#10;  env     &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  env_from_key &#61; optional&#40;map&#40;object&#40;&#123;&#10;    key  &#61; string&#10;    name &#61; string&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  liveness_probe &#61; optional&#40;object&#40;&#123;&#10;    action &#61; object&#40;&#123;&#10;      grpc &#61; optional&#40;object&#40;&#123;&#10;        port    &#61; optional&#40;number&#41;&#10;        service &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      http_get &#61; optional&#40;object&#40;&#123;&#10;        http_headers &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;        path         &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#10;    failure_threshold     &#61; optional&#40;number&#41;&#10;    initial_delay_seconds &#61; optional&#40;number&#41;&#10;    period_seconds        &#61; optional&#40;number&#41;&#10;    timeout_seconds       &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  ports &#61; optional&#40;map&#40;object&#40;&#123;&#10;    container_port &#61; optional&#40;number&#41;&#10;    name           &#61; optional&#40;string&#41;&#10;    protocol       &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  resources &#61; optional&#40;object&#40;&#123;&#10;    limits &#61; optional&#40;object&#40;&#123;&#10;      cpu    &#61; string&#10;      memory &#61; string&#10;    &#125;&#41;&#41;&#10;    requests &#61; optional&#40;object&#40;&#123;&#10;      cpu    &#61; string&#10;      memory &#61; string&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  startup_probe &#61; optional&#40;object&#40;&#123;&#10;    action &#61; object&#40;&#123;&#10;      grpc &#61; optional&#40;object&#40;&#123;&#10;        port    &#61; optional&#40;number&#41;&#10;        service &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      http_get &#61; optional&#40;object&#40;&#123;&#10;        http_headers &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;        path         &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      tcp_socket &#61; optional&#40;object&#40;&#123;&#10;        port &#61; optional&#40;number&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#10;    failure_threshold     &#61; optional&#40;number&#41;&#10;    initial_delay_seconds &#61; optional&#40;number&#41;&#10;    period_seconds        &#61; optional&#40;number&#41;&#10;    timeout_seconds       &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  volume_mounts &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [eventarc_triggers](variables.tf#L91) | Event arc triggers for different sources. | <code title="object&#40;&#123;&#10;  audit_log &#61; optional&#40;map&#40;object&#40;&#123;&#10;    method  &#61; string&#10;    service &#61; string&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;  pubsub                 &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  service_account_email  &#61; optional&#40;string&#41;&#10;  service_account_create &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [gen2_execution_environment](variables.tf#L113) | Use second generation execution environment. | <code>bool</code> |  | <code>false</code> |
| [iam](variables.tf#L119) | IAM bindings for Cloud Run service in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [ingress_settings](variables.tf#L125) | Ingress settings. | <code>string</code> |  | <code>null</code> |
| [labels](variables.tf#L138) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [prefix](variables.tf#L149) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [revision_annotations](variables.tf#L169) | Configure revision template annotations. | <code title="object&#40;&#123;&#10;  autoscaling &#61; optional&#40;object&#40;&#123;&#10;    max_scale &#61; number&#10;    min_scale &#61; number&#10;  &#125;&#41;&#41;&#10;  cloudsql_instances  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  vpcaccess_connector &#61; optional&#40;string&#41;&#10;  vpcaccess_egress    &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [revision_name](variables.tf#L184) | Revision name. | <code>string</code> |  | <code>null</code> |
| [service_account](variables.tf#L190) | Service account email. Unused if service account is auto-created. | <code>string</code> |  | <code>null</code> |
| [service_account_create](variables.tf#L196) | Auto-create service account. | <code>bool</code> |  | <code>false</code> |
| [startup_cpu_boost](variables.tf#L202) | Enable startup cpu boost. | <code>bool</code> |  | <code>false</code> |
| [tag_bindings](variables.tf#L208) | Tag bindings for this service, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [timeout_seconds](variables.tf#L215) | Maximum duration the instance is allowed for responding to a request. | <code>number</code> |  | <code>null</code> |
| [traffic](variables.tf#L221) | Traffic steering configuration. If revision name is null the latest revision will be used. | <code title="map&#40;object&#40;&#123;&#10;  percent &#61; number&#10;  latest  &#61; optional&#40;bool&#41;&#10;  tag     &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [volumes](variables.tf#L232) | Named volumes in containers in name => attributes format. | <code title="map&#40;object&#40;&#123;&#10;  secret_name  &#61; string&#10;  default_mode &#61; optional&#40;string&#41;&#10;  items &#61; optional&#40;map&#40;object&#40;&#123;&#10;    path &#61; string&#10;    mode &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vpc_connector_create](variables.tf#L246) | Populate this to create a VPC connector. You can then refer to it in the template annotations. | <code title="object&#40;&#123;&#10;  ip_cidr_range &#61; optional&#40;string&#41;&#10;  vpc_self_link &#61; optional&#40;string&#41;&#10;  machine_type  &#61; optional&#40;string&#41;&#10;  name          &#61; optional&#40;string&#41;&#10;  instances &#61; optional&#40;object&#40;&#123;&#10;    max &#61; optional&#40;number&#41;&#10;    min &#61; optional&#40;number&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  throughput &#61; optional&#40;object&#40;&#123;&#10;    max &#61; optional&#40;number&#41;&#10;    min &#61; optional&#40;number&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  subnet &#61; optional&#40;object&#40;&#123;&#10;    name       &#61; optional&#40;string&#41;&#10;    project_id &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L18) | Fully qualified service id. |  |
| [service](outputs.tf#L23) | Cloud Run service. |  |
| [service_account](outputs.tf#L28) | Service account resource. |  |
| [service_account_email](outputs.tf#L33) | Service account email. |  |
| [service_account_iam_email](outputs.tf#L38) | Service account email. |  |
| [service_name](outputs.tf#L46) | Cloud Run service name. |  |
| [vpc_connector](outputs.tf#L52) | VPC connector resource if created. |  |
<!-- END TFDOC -->
