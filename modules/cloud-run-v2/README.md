# Cloud Run Module

Cloud Run Services and Jobs, with support for IAM roles and Eventarc trigger creation. This module uses provider default value for `deletion_protection`, which means service is by default protected from removal (or reprovisioning).

<!-- BEGIN TOC -->
- [IAM and environment variables](#iam-and-environment-variables)
- [Mounting secrets as volumes](#mounting-secrets-as-volumes)
- [Mounting GCS buckets](#mounting-gcs-buckets)
- [Connecting to Cloud SQL database](#connecting-to-cloud-sql-database)
- [Direct VPC Egress](#direct-vpc-egress)
- [VPC Access Connector](#vpc-access-connector)
- [Using Customer-Managed Encryption Key](#using-customer-managed-encryption-key)
- [Deploying OpenTelemetry Collector sidecar](#deploying-opentelemetry-collector-sidecar)
- [Eventarc triggers](#eventarc-triggers)
  - [PubSub](#pubsub)
  - [Audit logs](#audit-logs)
  - [Using custom service accounts for triggers](#using-custom-service-accounts-for-triggers)
- [Cloud Run Invoker IAM Disable](#cloud-run-invoker-iam-disable)
- [Cloud Run Service Account](#cloud-run-service-account)
- [Creating Cloud Run Jobs](#creating-cloud-run-jobs)
- [Tag bindings](#tag-bindings)
- [IAP Configuration](#iap-configuration)
- [Variables](#variables)
- [Outputs](#outputs)
- [Fixtures](#fixtures)
<!-- END TOC -->

## IAM and environment variables

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
  deletion_protection = false
}
# tftest modules=2 resources=5 fixtures=fixtures/secret-credentials.tf inventory=service-iam-env.yaml e2e
```

## Mounting secrets as volumes

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
  deletion_protection = false
}
# tftest modules=2 resources=4 fixtures=fixtures/secret-credentials.tf inventory=service-volume-secretes.yaml e2e
```

## Mounting GCS buckets

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
        bucket = "/bucket"
      }
    }
  }
  revision = {
    gen2_execution_environment = true
  }
  volumes = {
    bucket = {
      gcs = {
        bucket       = var.bucket
        is_read_only = false
        mount_options = [ # Beta feature
          "metadata-cache-ttl-secs=120s",
          "type-cache-max-size-mb=4",
        ]
      }
    }
  }
  deletion_protection = false
}
# tftest inventory=gcs-mount.yaml e2e
```

## Connecting to Cloud SQL database

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      volume_mounts = {
        cloudsql = "/cloudsql"
      }
    }
  }
  volumes = {
    "cloudsql" = {
      cloud_sql_instances = [module.cloudsql-instance.connection_name]
    }
  }
  deletion_protection = false
}
# tftest fixtures=fixtures/cloudsql-instance.tf inventory=cloudsql.yaml e2e
```

## Direct VPC Egress

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = "hello"
  region     = var.region
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
      subnet = var.subnet.name
      tags   = ["tag1", "tag2", "tag3"]
    }
  }
  deletion_protection = false
}
# E2E test disabled due to b/332419038
# tftest modules=1 resources=1 inventory=service-direct-vpc.yaml
```

## VPC Access Connector

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
  deletion_protection = false
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
      min = 3
    }
  }
  deletion_protection = false
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
    throughput = {
      max = 300
      min = 200
    }
  }
  deletion_protection = false
}
# tftest modules=4 resources=59 fixtures=fixtures/shared-vpc.tf inventory=service-vpc-access-connector-create-sharedvpc.yaml e2e
```

## Using Customer-Managed Encryption Key

Deploy a Cloud Run service with environment variables encrypted using a Customer-Managed Encryption Key (CMEK). Ensure you specify the encryption_key with the full resource identifier of your Cloud KMS CryptoKey and that Cloud Run Service agent (`service-<PROJECT_NUMBER>@serverless-robot-prod.iam.gserviceaccount.com`) has permission to use the key, for example `roles/cloudkms.cryptoKeyEncrypterDecrypter` IAM role. This setup adds an extra layer of security by utilizing your own encryption keys.

```hcl
module "project" {
  source          = "./fabric/modules/project"
  name            = "cloudrun"
  billing_account = var.billing_account_id
  prefix          = var.prefix
  parent          = var.folder_id
  services = [
    "cloudkms.googleapis.com",
    "run.googleapis.com",
  ]
}

module "kms" {
  source     = "./fabric/modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = var.region
    name     = "${var.prefix}-keyring"
  }
  keys = {
    "key-regional" = {
    }
  }
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      module.project.service_agents.run.iam_email
    ]
  }
}

module "cloud_run" {
  source         = "./fabric/modules/cloud-run-v2"
  project_id     = module.project.project_id
  region         = var.region
  name           = "hello"
  encryption_key = module.kms.keys.key-regional.id
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  deletion_protection = false
}
# tftest modules=3 resources=11 e2e
```

## Deploying OpenTelemetry Collector sidecar

```yaml
# Reference: https://cloud.google.com/stackdriver/docs/instrumentation/opentelemetry-collector-cloud-run#gotc-provided-config

receivers:
  # Open two OTLP servers:
  # - On port 4317, open an OTLP GRPC server
  # - On port 4318, open an OTLP HTTP server
  #
  # Docs:
  # https://github.com/open-telemetry/opentelemetry-collector/tree/main/receiver/otlpreceiver
  otlp:
    protocols:
      grpc:
        endpoint: localhost:4317
      http:
        cors:
          # This effectively allows any origin
          # to make requests to the HTTP server.
          allowed_origins:
          - http://*
          - https://*
        endpoint: localhost:4318

  # Using the prometheus scraper, scrape the Collector's self metrics.
  #
  # Docs:
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/prometheusreceiver
  # https://opentelemetry.io/docs/collector/internal-telemetry/
  prometheus/self-metrics:
    config:
      scrape_configs:
      - job_name: otel-self-metrics
        scrape_interval: 1m
        static_configs:
        - targets:
          - localhost:8888

processors:
  # The batch processor is in place to regulate both the number of requests
  # being made and the size of those requests.
  #
  # Docs:
  # https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/batchprocessor
  batch:
    send_batch_max_size: 200
    send_batch_size: 200
    timeout: 5s

  # The memorylimiter will check the memory usage of the collector process.
  #
  # Docs:
  # https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/memorylimiterprocessor
  memory_limiter:
    check_interval: 1s
    limit_percentage: 65
    spike_limit_percentage: 20

  # The resourcedetection processor is configured to detect GCP resources.
  # Resource attributes that represent the GCP resource the collector is
  # running on will be attached to all telemetry that goes through this
  # processor.
  #
  # Docs:
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourcedetectionprocessor
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourcedetectionprocessor#gcp-metadata
  resourcedetection:
    detectors: [gcp]
    timeout: 10s

  # The transform/collision processor ensures that any attributes that may
  # collide with the googlemanagedprometheus exporter's monitored resource
  # construction are moved to a similar name that is not reserved.
  transform/collision:
    metric_statements:
    - context: datapoint
      statements:
      - set(attributes["exported_location"], attributes["location"])
      - delete_key(attributes, "location")
      - set(attributes["exported_cluster"], attributes["cluster"])
      - delete_key(attributes, "cluster")
      - set(attributes["exported_namespace"], attributes["namespace"])
      - delete_key(attributes, "namespace")
      - set(attributes["exported_job"], attributes["job"])
      - delete_key(attributes, "job")
      - set(attributes["exported_instance"], attributes["instance"])
      - delete_key(attributes, "instance")
      - set(attributes["exported_project_id"], attributes["project_id"])
      - delete_key(attributes, "project_id")

exporters:
  # The googlecloud exporter will export telemetry to different
  # Google Cloud services:
  # Logs -> Cloud Logging
  # Metrics -> Cloud Monitoring
  # Traces -> Cloud Trace
  #
  # Docs:
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/googlecloudexporter
  googlecloud:
    log:
      default_log_name: opentelemetry-collector

  # The googlemanagedprometheus exporter will send metrics to
  # Google Managed Service for Prometheus.
  #
  # Docs:
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/googlemanagedprometheusexporter
  googlemanagedprometheus:

extensions:
  # Opens an endpoint on 13133 that can be used to check the
  # status of the collector. Since this does not configure the
  # `path` config value, the endpoint will default to `/`.
  #
  # When running on Cloud Run, this extension is required and not optional.
  # In other environments it is recommended but may not be required for operation
  # (i.e. in Container-Optimized OS or other GCE environments).
  #
  # Docs:
  # https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/healthcheckextension
  health_check:
    endpoint: 0.0.0.0:13133

service:
  extensions:
  - health_check
  pipelines:
    logs:
      receivers:
      - otlp
      processors:
      - resourcedetection
      - memory_limiter
      - batch
      exporters:
      - googlecloud
    metrics/otlp:
      receivers:
      - otlp
      processors:
      - transform/collision
      - resourcedetection
      - memory_limiter
      - batch
      exporters:
      - googlemanagedprometheus
    metrics/self-metrics:
      receivers:
      - prometheus/self-metrics
      processors:
      - resourcedetection
      - memory_limiter
      - batch
      exporters:
      - googlemanagedprometheus
    traces:
      receivers:
      - otlp
      processors:
      - resourcedetection
      - memory_limiter
      - batch
      exporters:
      - googlecloud
  telemetry:
    metrics:
      address: localhost:8888

# tftest-file id=otel-config path=config/otel-config.yaml
```

```hcl
module "secrets" {
  source     = "./fabric/modules/secret-manager"
  project_id = var.project_id
  secrets = {
    otel-config = {}
  }
  iam = {
    otel-config = {
      "roles/secretmanager.secretAccessor" = [
        "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com",
      ]
    }
  }
  versions = {
    otel-config = {
      v1 = { enabled = true, data = file("${path.module}/config/otel-config.yaml") }
    }
  }
}

module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  region     = var.region
  name       = "hello"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      ports = {
        default = {
          container_port = 3000
        }
      }
      depends_on = ["collector"]
    }
    collector = {
      image = "us-docker.pkg.dev/cloud-ops-agents-artifacts/google-cloud-opentelemetry-collector/otelcol-google:0.122.1"
      startup_probe = {
        http_get = {
          path = "/"
          port = 13133
        }
        timeout_seconds = 30
        period_seconds  = 30
      }
      liveness_probe = {
        http_get = {
          path = "/"
          port = 13133
        }
        timeout_seconds = 30
        period_seconds  = 30
      }
      volume_mounts = {
        "otel-config" = "/etc/otelcol-google/"
      }
    }
  }
  volumes = {
    otel-config = {
      secret = {
        name    = "otel-config"
        version = "1"
        path    = "config.yaml"
      }
    }
  }
  deletion_protection = false
}
# tftest modules=2 resources=4 files=otel-config inventory=service-otel-sidecar.yaml e2e
```

## Eventarc triggers

### PubSub

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
  deletion_protection = false
}
# tftest modules=2 resources=4 fixtures=fixtures/pubsub.tf inventory=service-eventarc-pubsub.yaml e2e
```

### Audit logs

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
  deletion_protection = false
}
# tftest modules=1 resources=4 inventory=service-eventarc-auditlogs-sa-create.yaml
```

### Using custom service accounts for triggers

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
  deletion_protection = false
}
# tftest modules=2 resources=6 fixtures=fixtures/pubsub.tf inventory=service-eventarc-pubsub-sa-create.yaml e2e
```

## Cloud Run Invoker IAM Disable

To disables IAM permission check for `run.routes.invoke` for callers of this service set the `invoker_iam_disabled` variable of the module to `true` (default `false`). There should be no requirement to pass the `roles/run.invoker` to the IAM block to enable public access. This allows for the org policy `domain restricted sharing` org policy remain enabled.

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
  invoker_iam_disabled = true
  deletion_protection  = false
}
# tftest modules=1 resources=1 inventory=service-invoker-iam-disable.yaml e2e
```

## Cloud Run Service Account

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
  deletion_protection    = false
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
  service_account     = module.iam-service-account.email
  deletion_protection = false
}
# tftest modules=2 resources=2 fixtures=fixtures/iam-service-account.tf inventory=service-external-sa.yaml e2e
```

## Creating Cloud Run Jobs

To create a job instead of service set `create_job` to `true`. Jobs support all functions above apart from triggers.

Unsupported variables / attributes:

- ingress
- revision.gen2_execution_environment (they run by default in gen2)
- revision.name
- containers.liveness_probe
- containers.startup_probe
- containers.resources.cpu_idle
- containers.resources.startup_cpu_boost

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
  deletion_protection = false
}

# tftest modules=1 resources=2 inventory=job-iam-env.yaml e2e
```

## Tag bindings

Tag bindings are not yet supported for jobs. Refer to the [Creating and managing tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) documentation for details on usage.

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
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  tag_bindings = {
    env-sandbox = module.org.tag_values["environment/sandbox"].id
  }
}
# tftest modules=2 resources=7
```

## IAP Configuration

IAP is only supported for service.  Refer to the [Configure IAP directly on cloud run](https://cloud.google.com/run/docs/securing/identity-aware-proxy-cloud-run) documentation for details on usage.

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
    }
  }

  iap_config = {
    iam = ["group:abc@domain.com"]
  }

}
# tftest modules=1 resources=2
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L206) | Name used for Cloud Run service. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L221) | Project id used for all resources. | <code>string</code> | ✓ |  |
| [region](variables.tf#L226) | Region used for all resources. | <code>string</code> | ✓ |  |
| [containers](variables.tf#L17) | Containers in name => attributes format. | <code title="map&#40;object&#40;&#123;&#10;  image      &#61; string&#10;  depends_on &#61; optional&#40;list&#40;string&#41;&#41;&#10;  command    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  args       &#61; optional&#40;list&#40;string&#41;&#41;&#10;  env        &#61; optional&#40;map&#40;string&#41;&#41;&#10;  env_from_key &#61; optional&#40;map&#40;object&#40;&#123;&#10;    secret  &#61; string&#10;    version &#61; string&#10;  &#125;&#41;&#41;&#41;&#10;  liveness_probe &#61; optional&#40;object&#40;&#123;&#10;    grpc &#61; optional&#40;object&#40;&#123;&#10;      port    &#61; optional&#40;number&#41;&#10;      service &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    http_get &#61; optional&#40;object&#40;&#123;&#10;      http_headers &#61; optional&#40;map&#40;string&#41;&#41;&#10;      path         &#61; optional&#40;string&#41;&#10;      port         &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    failure_threshold     &#61; optional&#40;number&#41;&#10;    initial_delay_seconds &#61; optional&#40;number&#41;&#10;    period_seconds        &#61; optional&#40;number&#41;&#10;    timeout_seconds       &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  ports &#61; optional&#40;map&#40;object&#40;&#123;&#10;    container_port &#61; optional&#40;number&#41;&#10;    name           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  resources &#61; optional&#40;object&#40;&#123;&#10;    limits &#61; optional&#40;object&#40;&#123;&#10;      cpu    &#61; string&#10;      memory &#61; string&#10;    &#125;&#41;&#41;&#10;    cpu_idle          &#61; optional&#40;bool&#41;&#10;    startup_cpu_boost &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  startup_probe &#61; optional&#40;object&#40;&#123;&#10;    grpc &#61; optional&#40;object&#40;&#123;&#10;      port    &#61; optional&#40;number&#41;&#10;      service &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    http_get &#61; optional&#40;object&#40;&#123;&#10;      http_headers &#61; optional&#40;map&#40;string&#41;&#41;&#10;      path         &#61; optional&#40;string&#41;&#10;      port         &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    tcp_socket &#61; optional&#40;object&#40;&#123;&#10;      port &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    failure_threshold     &#61; optional&#40;number&#41;&#10;    initial_delay_seconds &#61; optional&#40;number&#41;&#10;    period_seconds        &#61; optional&#40;number&#41;&#10;    timeout_seconds       &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  volume_mounts &#61; optional&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [create_job](variables.tf#L80) | Create Cloud Run Job instead of Service. | <code>bool</code> |  | <code>false</code> |
| [custom_audiences](variables.tf#L86) | Custom audiences for service. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [deletion_protection](variables.tf#L92) | Deletion protection setting for this Cloud Run service. | <code>string</code> |  | <code>null</code> |
| [encryption_key](variables.tf#L98) | The full resource name of the Cloud KMS CryptoKey. | <code>string</code> |  | <code>null</code> |
| [eventarc_triggers](variables.tf#L104) | Event arc triggers for different sources. | <code title="object&#40;&#123;&#10;  audit_log &#61; optional&#40;map&#40;object&#40;&#123;&#10;    method  &#61; string&#10;    service &#61; string&#10;  &#125;&#41;&#41;&#41;&#10;  pubsub                 &#61; optional&#40;map&#40;string&#41;&#41;&#10;  service_account_email  &#61; optional&#40;string&#41;&#10;  service_account_create &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iam](variables.tf#L122) | IAM bindings for Cloud Run service in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [iap_config](variables.tf#L128) | If present, turns on Identity-Aware Proxy (IAP) for the Cloud Run service. | <code title="object&#40;&#123;&#10;  iam          &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  iam_additive &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [ingress](variables.tf#L153) | Ingress settings. | <code>string</code> |  | <code>null</code> |
| [invoker_iam_disabled](variables.tf#L170) | Disables IAM permission check for run.routes.invoke for callers of this service. | <code>bool</code> |  | <code>false</code> |
| [labels](variables.tf#L176) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [launch_stage](variables.tf#L182) | The launch stage as defined by Google Cloud Platform Launch Stages. | <code>string</code> |  | <code>null</code> |
| [managed_revision](variables.tf#L199) | Whether the Terraform module should control the deployment of revisions. | <code>bool</code> |  | <code>true</code> |
| [prefix](variables.tf#L211) | Optional prefix used for resource names. | <code>string</code> |  | <code>null</code> |
| [revision](variables.tf#L231) | Revision template configurations. | <code title="object&#40;&#123;&#10;  labels                     &#61; optional&#40;map&#40;string&#41;&#41;&#10;  name                       &#61; optional&#40;string&#41;&#10;  gen2_execution_environment &#61; optional&#40;bool&#41;&#10;  max_concurrency            &#61; optional&#40;number&#41;&#10;  max_instance_count         &#61; optional&#40;number&#41;&#10;  min_instance_count         &#61; optional&#40;number&#41;&#10;  job &#61; optional&#40;object&#40;&#123;&#10;    max_retries &#61; optional&#40;number&#41;&#10;    task_count  &#61; optional&#40;number&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  vpc_access &#61; optional&#40;object&#40;&#123;&#10;    connector &#61; optional&#40;string&#41;&#10;    egress    &#61; optional&#40;string&#41;&#10;    network   &#61; optional&#40;string&#41;&#10;    subnet    &#61; optional&#40;string&#41;&#10;    tags      &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  timeout &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_account](variables.tf#L270) | Service account email. Unused if service account is auto-created. | <code>string</code> |  | <code>null</code> |
| [service_account_create](variables.tf#L276) | Auto-create service account. | <code>bool</code> |  | <code>false</code> |
| [tag_bindings](variables.tf#L282) | Tag bindings for this service, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [volumes](variables.tf#L289) | Named volumes in containers in name => attributes format. | <code title="map&#40;object&#40;&#123;&#10;  secret &#61; optional&#40;object&#40;&#123;&#10;    name         &#61; string&#10;    default_mode &#61; optional&#40;string&#41;&#10;    path         &#61; optional&#40;string&#41;&#10;    version      &#61; optional&#40;string&#41;&#10;    mode         &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  cloud_sql_instances &#61; optional&#40;list&#40;string&#41;&#41;&#10;  empty_dir_size      &#61; optional&#40;string&#41;&#10;  gcs &#61; optional&#40;object&#40;&#123;&#10;    bucket       &#61; string&#10;    is_read_only &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  nfs &#61; optional&#40;object&#40;&#123;&#10;    server       &#61; string&#10;    path         &#61; optional&#40;string&#41;&#10;    is_read_only &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vpc_connector_create](variables-vpcconnector.tf#L17) | Populate this to create a Serverless VPC Access connector. | <code title="object&#40;&#123;&#10;  ip_cidr_range &#61; optional&#40;string&#41;&#10;  machine_type  &#61; optional&#40;string&#41;&#10;  name          &#61; optional&#40;string&#41;&#10;  network       &#61; optional&#40;string&#41;&#10;  instances &#61; optional&#40;object&#40;&#123;&#10;    max &#61; optional&#40;number&#41;&#10;    min &#61; optional&#40;number&#41;&#10;    &#125;&#41;, &#123;&#125;&#10;  &#41;&#10;  throughput &#61; optional&#40;object&#40;&#123;&#10;    max &#61; optional&#40;number&#41;&#10;    min &#61; optional&#40;number&#41;&#10;    &#125;&#41;, &#123;&#125;&#10;  &#41;&#10;  subnet &#61; optional&#40;object&#40;&#123;&#10;    name       &#61; optional&#40;string&#41;&#10;    project_id &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified job or service id. |  |
| [invoke_command](outputs.tf#L22) | Command to invoke Cloud Run Service / submit job. |  |
| [job](outputs.tf#L40) | Cloud Run Job. |  |
| [service](outputs.tf#L45) | Cloud Run Service. |  |
| [service_account](outputs.tf#L50) | Service account resource. |  |
| [service_account_email](outputs.tf#L55) | Service account email. |  |
| [service_account_iam_email](outputs.tf#L60) | Service account email. |  |
| [service_name](outputs.tf#L68) | Cloud Run service name. |  |
| [service_uri](outputs.tf#L73) | Main URI in which the service is serving traffic. |  |
| [vpc_connector](outputs.tf#L78) | VPC connector resource if created. |  |

## Fixtures

- [cloudsql-instance.tf](../../tests/fixtures/cloudsql-instance.tf)
- [iam-service-account.tf](../../tests/fixtures/iam-service-account.tf)
- [pubsub.tf](../../tests/fixtures/pubsub.tf)
- [secret-credentials.tf](../../tests/fixtures/secret-credentials.tf)
- [shared-vpc.tf](../../tests/fixtures/shared-vpc.tf)
- [vpc-connector.tf](../../tests/fixtures/vpc-connector.tf)
<!-- END TFDOC -->
