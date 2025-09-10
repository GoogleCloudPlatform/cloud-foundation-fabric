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
  - [GCS bucket](#gcs-bucket)
- [Cloud Run Invoker IAM Disable](#cloud-run-invoker-iam-disable)
- [Cloud Run Service Account](#cloud-run-service-account)
- [Creating Cloud Run Jobs](#creating-cloud-run-jobs)
- [Tag bindings](#tag-bindings)
- [IAP Configuration](#iap-configuration)
- [Adding GPUs](#adding-gpus)
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
          version = module.secret-manager.version_versions["credentials/v1"]
        }
      }
    }
  }
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  deletion_protection = false
}
# tftest fixtures=fixtures/secret-credentials.tf inventory=service-iam-env.yaml e2e skip-tofu
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
# tftest fixtures=fixtures/secret-credentials.tf inventory=service-volume-secretes.yaml e2e skip-tofu
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
  service_config = {
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
    vpc_access = {
      egress = "ALL_TRAFFIC"
      subnet = var.subnet.name
      tags   = ["tag1", "tag2", "tag3"]
    }
  }
  service_config = {
    gen2_execution_environment = true
    max_instance_count         = 20
  }
  deletion_protection = false
}
# E2E test disabled due to b/332419038
# tftest inventory=service-direct-vpc.yaml
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
  service_config = {
    vpc_access = {
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC"
    }
  }
  deletion_protection = false
}
# tftest modules=1 resources=2 fixtures=fixtures/vpc-connector.tf inventory=service-vpc-access-connector.yaml e2e
```

If creation of the VPC Access Connector is required, use the `vpc_connector_create` variable which also supports optional attributes like number of instances, machine type, or throughput. The connector will be used automatically by Cloud Run Service and Job. Worker Pool does not support connector.

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
# tftest inventory=service-vpc-access-connector-create.yaml e2e
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
# tftest fixtures=fixtures/shared-vpc.tf inventory=service-vpc-access-connector-create-sharedvpc.yaml e2e
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
    otel-config = {
      iam = {
        "roles/secretmanager.secretAccessor" = [
          "serviceAccount:${var.project_number}-compute@developer.gserviceaccount.com"
        ]
      }
      versions = {
        v1 = {
          data = file("${path.module}/config/otel-config.yaml")
        }
      }
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
# tftest files=otel-config inventory=service-otel-sidecar.yaml e2e skip-tofu
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
  service_config = {
    eventarc_triggers = {
      pubsub = {
        topic-1 = module.pubsub.topic.name
      }
    }
  }
  deletion_protection = false
}
# tftest fixtures=fixtures/pubsub.tf inventory=service-eventarc-pubsub.yaml e2e
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
  service_config = {
    eventarc_triggers = {
      audit_log = {
        setiampolicy = {
          method  = "SetIamPolicy"
          service = "cloudresourcemanager.googleapis.com"
        }
      }
      service_account_email = module.iam-service-account.email
    }
  }
  iam = {
    "roles/run.invoker" = [module.iam-service-account.iam_email]
  }
  deletion_protection = false
  depends_on          = [google_project_iam_member.eventarc_receiver]
}

resource "google_project_iam_member" "eventarc_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = module.iam-service-account.iam_email
}
# tftest fixtures=fixtures/iam-service-account.tf inventory=service-eventarc-auditlogs-external-sa.yaml e2e
```

### GCS bucket

This deploys a Cloud Run service that will be triggered when files are uploaded to a GCS bucket.

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
  service_config = {
    eventarc_triggers = {
      storage = {
        bucket-upload = {
          bucket = module.gcs.name
          path   = "/webhook" # optional: URL path for the Cloud Run service
        }
      }
      service_account_email = module.iam-service-account.email
    }
  }
  deletion_protection = false
  depends_on = [
    google_project_iam_member.gcs_pubsb_publisher,
    google_project_iam_member.trigger_sa_event_receiver,
  ]
}

resource "google_project_iam_member" "trigger_sa_event_receiver" {
  member  = module.iam-service-account.iam_email
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
}

resource "google_project_iam_member" "gcs_pubsb_publisher" {
  member  = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"
  project = var.project_id
  role    = "roles/pubsub.publisher"
}

# tftest fixtures=fixtures/gcs.tf,fixtures/iam-service-account.tf inventory=service-eventarc-storage.yaml e2e
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
  service_config = {
    invoker_iam_disabled = true
  }
  deletion_protection = false
}
# tftest inventory=service-invoker-iam-disable.yaml e2e
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
# tftest inventory=service-sa-create.yaml e2e
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

To create a job instead of service set `type` to `JOB`. Jobs support all functions above apart from triggers.

Unsupported variables / attributes:

- ingress
- revision.gen2_execution_environment (they run by default in gen2)
- revision.name
- containers.liveness_probe
- containers.startup_probe
- containers.resources.cpu_idle
- containers.resources.startup_cpu_boost

Additional configuration can be passwed as `job_config`:

- max_retries - maximum of retries per task
- task_count - desired number of tasks
- timeout - max allowed time per task, in seconds with up to nine fractional digits, ending with 's'. Example: `3.5s`

```hcl
module "cloud_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = "hello"
  region     = var.region
  type       = "JOB"
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

# tftest inventory=job-iam-env.yaml e2e
```

## Tag bindings

Tag bindings are not yet supported for Worker Pool. Refer to the [Creating and managing tags](https://cloud.google.com/resource-manager/docs/tags/tags-creating-and-managing) documentation for details on usage.

```hcl
module "project" {
  source = "./fabric/modules/project"
  name   = var.project_id
  project_reuse = {
    use_data_source = false
    attributes = {
      name   = var.project_id
      number = var.project_number
    }
  }
  tags = {
    run_environment = {
      description = "Environment specification."
      values = {
        dev     = {}
        prod    = {}
        sandbox = {}
      }
    }
  }
}

module "cloud_run_service" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = "hello-service"
  region     = var.region
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  tag_bindings = {
    env-sandbox = module.project.tag_values["run_environment/sandbox"].id
  }
  deletion_protection = false
}

module "cloud_run_job" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = "hello-job"
  region     = var.region
  type       = "JOB"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
    }
  }
  tag_bindings = {
    env-sandbox = module.project.tag_values["run_environment/sandbox"].id
  }
  deletion_protection = false
}

# tftest inventory=tags.yaml e2e
```

## IAP Configuration

IAP is only supported for service. Refer to the [Configure IAP directly on cloud run](https://cloud.google.com/run/docs/securing/identity-aware-proxy-cloud-run) documentation for details on usage.

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
  service_config = {
    iap_config = {
      iam = ["group:${var.group_email}"]
    }
  }
  deletion_protection = false
}
# tftest modules=1 resources=2 e2e
```

## Adding GPUs

GPU support is available for all types of Cloud Run resources: jobs, services and worker pools.

```hcl
module "job" {
  source       = "./fabric/modules/cloud-run-v2"
  project_id   = var.project_id
  name         = "job"
  region       = var.region
  launch_stage = "BETA"
  revision = {
    gpu_zonal_redundancy_disabled = true
    node_selector = {
      accelerator = "nvidia-l4"
    }
  }
  type = "JOB"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      resources = {
        limits = {
          cpu              = "4000m"
          memory           = "16Gi"
          "nvidia.com/gpu" = "1"
        }
      }
    }
  }
  deletion_protection = false
}
# tftest inventory=gpu-job.yaml
```

```hcl
module "service" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = "service"
  region     = var.region
  revision = {
    gpu_zonal_redundancy_disabled = true
    node_selector = {
      accelerator = "nvidia-l4"
    }
  }
  service_config = {
    gen2_execution_environment = true
  }
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      resources = {
        limits = {
          cpu              = "4000m"
          memory           = "16Gi"
          "nvidia.com/gpu" = "1"
        }
      }
    }
  }
  deletion_protection = false
}
# tftest inventory=gpu-service.yaml e2e
```

```hcl
module "worker" {
  source       = "./fabric/modules/cloud-run-v2"
  project_id   = var.project_id
  name         = "worker"
  region       = var.region
  launch_stage = "BETA"
  revision = {
    gpu_zonal_redundancy_disabled = true
    node_selector = {
      accelerator = "nvidia-l4"
    }
  }
  type = "WORKERPOOL"
  containers = {
    hello = {
      image = "us-docker.pkg.dev/cloudrun/container/hello"
      resources = {
        limits = {
          cpu              = "4000m"
          memory           = "16Gi"
          "nvidia.com/gpu" = "1"
        }
      }
    }
  }
  deletion_protection = false
}
# tftest inventory=gpu-workerpool.yaml e2e
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L160) | Name used for Cloud Run service. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L165) | Project id used for all resources. | <code>string</code> | ✓ |  |
| [region](variables.tf#L170) | Region used for all resources. | <code>string</code> | ✓ |  |
| [containers](variables.tf#L17) | Containers in name => attributes format. | <code title="map&#40;object&#40;&#123;&#10;  image      &#61; string&#10;  depends_on &#61; optional&#40;list&#40;string&#41;&#41;&#10;  command    &#61; optional&#40;list&#40;string&#41;&#41;&#10;  args       &#61; optional&#40;list&#40;string&#41;&#41;&#10;  env        &#61; optional&#40;map&#40;string&#41;&#41;&#10;  env_from_key &#61; optional&#40;map&#40;object&#40;&#123;&#10;    secret  &#61; string&#10;    version &#61; string&#10;  &#125;&#41;&#41;&#41;&#10;  liveness_probe &#61; optional&#40;object&#40;&#123;&#10;    grpc &#61; optional&#40;object&#40;&#123;&#10;      port    &#61; optional&#40;number&#41;&#10;      service &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    http_get &#61; optional&#40;object&#40;&#123;&#10;      http_headers &#61; optional&#40;map&#40;string&#41;&#41;&#10;      path         &#61; optional&#40;string&#41;&#10;      port         &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    failure_threshold     &#61; optional&#40;number&#41;&#10;    initial_delay_seconds &#61; optional&#40;number&#41;&#10;    period_seconds        &#61; optional&#40;number&#41;&#10;    timeout_seconds       &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  ports &#61; optional&#40;map&#40;object&#40;&#123;&#10;    container_port &#61; optional&#40;number&#41;&#10;    name           &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  resources &#61; optional&#40;object&#40;&#123;&#10;    limits            &#61; optional&#40;map&#40;string&#41;&#41;&#10;    cpu_idle          &#61; optional&#40;bool&#41;&#10;    startup_cpu_boost &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  startup_probe &#61; optional&#40;object&#40;&#123;&#10;    grpc &#61; optional&#40;object&#40;&#123;&#10;      port    &#61; optional&#40;number&#41;&#10;      service &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#10;    http_get &#61; optional&#40;object&#40;&#123;&#10;      http_headers &#61; optional&#40;map&#40;string&#41;&#41;&#10;      path         &#61; optional&#40;string&#41;&#10;      port         &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    tcp_socket &#61; optional&#40;object&#40;&#123;&#10;      port &#61; optional&#40;number&#41;&#10;    &#125;&#41;&#41;&#10;    failure_threshold     &#61; optional&#40;number&#41;&#10;    initial_delay_seconds &#61; optional&#40;number&#41;&#10;    period_seconds        &#61; optional&#40;number&#41;&#10;    timeout_seconds       &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  volume_mounts &#61; optional&#40;map&#40;string&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [deletion_protection](variables.tf#L97) | Deletion protection setting for this Cloud Run service. | <code>string</code> |  | <code>null</code> |
| [encryption_key](variables.tf#L103) | The full resource name of the Cloud KMS CryptoKey. | <code>string</code> |  | <code>null</code> |
| [iam](variables.tf#L109) | IAM bindings for Cloud Run service in {ROLE => [MEMBERS]} format. | <code>map&#40;list&#40;string&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [job_config](variables.tf#L115) | Cloud Run Job specific configuration. | <code title="object&#40;&#123;&#10;  max_retries &#61; optional&#40;number&#41;&#10;  task_count  &#61; optional&#40;number&#41;&#10;  timeout     &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [labels](variables.tf#L130) | Resource labels. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [launch_stage](variables.tf#L136) | The launch stage as defined by Google Cloud Platform Launch Stages. | <code>string</code> |  | <code>null</code> |
| [managed_revision](variables.tf#L153) | Whether the Terraform module should control the deployment of revisions. | <code>bool</code> |  | <code>true</code> |
| [revision](variables.tf#L175) | Revision template configurations. | <code title="object&#40;&#123;&#10;  gpu_zonal_redundancy_disabled &#61; optional&#40;bool&#41;&#10;  labels                        &#61; optional&#40;map&#40;string&#41;&#41;&#10;  name                          &#61; optional&#40;string&#41;&#10;  node_selector &#61; optional&#40;object&#40;&#123;&#10;    accelerator &#61; string&#10;  &#125;&#41;&#41;&#10;  vpc_access &#61; optional&#40;object&#40;&#123;&#10;    connector &#61; optional&#40;string&#41;&#10;    egress    &#61; optional&#40;string&#41;&#10;    network   &#61; optional&#40;string&#41;&#10;    subnet    &#61; optional&#40;string&#41;&#10;    tags      &#61; optional&#40;list&#40;string&#41;&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  timeout &#61; optional&#40;string&#41;&#10;  gen2_execution_environment &#61; optional&#40;any&#41; &#35; DEPRECATED&#10;  job                        &#61; optional&#40;any&#41; &#35; DEPRECATED&#10;  max_concurrency            &#61; optional&#40;any&#41; &#35; DEPRECATED&#10;  max_instance_count         &#61; optional&#40;any&#41; &#35; DEPRECATED&#10;  min_instance_count         &#61; optional&#40;any&#41; &#35; DEPRECATED&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [service_account](variables.tf#L236) | Service account email. Unused if service account is auto-created. | <code>string</code> |  | <code>null</code> |
| [service_account_create](variables.tf#L242) | Auto-create service account. | <code>bool</code> |  | <code>false</code> |
| [service_config](variables.tf#L248) | Cloud Run service specific configuration options. | <code title="object&#40;&#123;&#10;  custom_audiences &#61; optional&#40;list&#40;string&#41;, null&#41;&#10;  eventarc_triggers &#61; optional&#40;&#10;    object&#40;&#123;&#10;      audit_log &#61; optional&#40;map&#40;object&#40;&#123;&#10;        method  &#61; string&#10;        service &#61; string&#10;      &#125;&#41;&#41;&#41;&#10;      pubsub &#61; optional&#40;map&#40;string&#41;&#41;&#10;      storage &#61; optional&#40;map&#40;object&#40;&#123;&#10;        bucket &#61; string&#10;        path   &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#41;&#10;      service_account_email &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;  gen2_execution_environment &#61; optional&#40;bool, false&#41;&#10;  iap_config &#61; optional&#40;object&#40;&#123;&#10;    iam          &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    iam_additive &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  &#125;&#41;, null&#41;&#10;  ingress              &#61; optional&#40;string, null&#41;&#10;  invoker_iam_disabled &#61; optional&#40;bool, false&#41;&#10;  max_concurrency      &#61; optional&#40;number&#41;&#10;  scaling &#61; optional&#40;object&#40;&#123;&#10;    max_instance_count &#61; optional&#40;number&#41;&#10;    min_instance_count &#61; optional&#40;number&#41;&#10;  &#125;&#41;&#41;&#10;  timeout &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [tag_bindings](variables.tf#L311) | Tag bindings for this service, in key => tag value id format. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [type](variables.tf#L318) | Type of Cloud Run resource to deploy: JOB, SERVICE or WORKERPOOL. | <code>string</code> |  | <code>&#34;SERVICE&#34;</code> |
| [volumes](variables.tf#L328) | Named volumes in containers in name => attributes format. | <code title="map&#40;object&#40;&#123;&#10;  secret &#61; optional&#40;object&#40;&#123;&#10;    name         &#61; string&#10;    default_mode &#61; optional&#40;string&#41;&#10;    path         &#61; optional&#40;string&#41;&#10;    version      &#61; optional&#40;string&#41;&#10;    mode         &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  cloud_sql_instances &#61; optional&#40;list&#40;string&#41;&#41;&#10;  empty_dir_size      &#61; optional&#40;string&#41;&#10;  gcs &#61; optional&#40;object&#40;&#123;&#10;    bucket       &#61; string&#10;    is_read_only &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  nfs &#61; optional&#40;object&#40;&#123;&#10;    server       &#61; string&#10;    path         &#61; optional&#40;string&#41;&#10;    is_read_only &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [vpc_connector_create](variables-vpcconnector.tf#L17) | Populate this to create a Serverless VPC Access connector. | <code title="object&#40;&#123;&#10;  ip_cidr_range &#61; optional&#40;string&#41;&#10;  machine_type  &#61; optional&#40;string&#41;&#10;  name          &#61; optional&#40;string&#41;&#10;  network       &#61; optional&#40;string&#41;&#10;  instances &#61; optional&#40;object&#40;&#123;&#10;    max &#61; optional&#40;number&#41;&#10;    min &#61; optional&#40;number&#41;&#10;    &#125;&#41;, &#123;&#125;&#10;  &#41;&#10;  throughput &#61; optional&#40;object&#40;&#123;&#10;    max &#61; optional&#40;number&#41;&#10;    min &#61; optional&#40;number&#41;&#10;    &#125;&#41;, &#123;&#125;&#10;  &#41;&#10;  subnet &#61; optional&#40;object&#40;&#123;&#10;    name       &#61; optional&#40;string&#41;&#10;    project_id &#61; optional&#40;string&#41;&#10;  &#125;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [workerpool_config](variables.tf#L362) | Cloud Run Worker Pool specific configuration. | <code title="object&#40;&#123;&#10;  scaling &#61; optional&#40;object&#40;&#123;&#10;    manual_instance_count &#61; optional&#40;number&#41;&#10;    max_instance_count    &#61; optional&#40;number&#41;&#10;    min_instance_count    &#61; optional&#40;number&#41;&#10;    mode                  &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified job or service id. |  |
| [invoke_command](outputs.tf#L22) | Command to invoke Cloud Run Service / submit job. |  |
| [job](outputs.tf#L27) | Cloud Run Job. |  |
| [resource](outputs.tf#L32) | Cloud Run resource (job, service or worker_pool). |  |
| [resource_name](outputs.tf#L37) | Cloud Run resource (job, service or workerpool)  service name. |  |
| [service](outputs.tf#L42) | Cloud Run Service. |  |
| [service_account](outputs.tf#L46) | Service account resource. |  |
| [service_account_email](outputs.tf#L51) | Service account email. |  |
| [service_account_iam_email](outputs.tf#L56) | Service account email. |  |
| [service_name](outputs.tf#L64) | Cloud Run service name. |  |
| [service_uri](outputs.tf#L69) | Main URI in which the service is serving traffic. |  |
| [vpc_connector](outputs.tf#L74) | VPC connector resource if created. |  |

## Fixtures

- [cloudsql-instance.tf](../../tests/fixtures/cloudsql-instance.tf)
- [gcs.tf](../../tests/fixtures/gcs.tf)
- [iam-service-account.tf](../../tests/fixtures/iam-service-account.tf)
- [pubsub.tf](../../tests/fixtures/pubsub.tf)
- [secret-credentials.tf](../../tests/fixtures/secret-credentials.tf)
- [shared-vpc.tf](../../tests/fixtures/shared-vpc.tf)
- [vpc-connector.tf](../../tests/fixtures/vpc-connector.tf)
<!-- END TFDOC -->
