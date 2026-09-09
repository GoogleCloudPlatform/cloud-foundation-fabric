# Application Factory

This module implements a YAML-driven factory for the resource-level components of a single application or service. It belongs to the same family as the [project factory](../project-factory/) and the [VPC factory](../net-vpc-factory/), and wraps the existing low-level modules in this repository without managing any Terraform resource directly.

Each resource is described by one YAML file in a per-type folder, whose name provides the resource name. The YAML interface of each resource type mirrors the variables of the wrapped module, so that the [module documentation](../) can be used as a reference, and the [JSON schemas](./schemas/) in this module can be used to validate data files.

<!-- BEGIN TOC -->
- [Design](#design)
  - [Resource types and phases](#resource-types-and-phases)
  - [Context interpolation and enrichment](#context-interpolation-and-enrichment)
  - [Resource names](#resource-names)
  - [Secret Manager and reserved addresses](#secret-manager-and-reserved-addresses)
- [Example](#example)
- [Files](#files)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Design

### Resource types and phases

Resources are created in phases, so that resources in a later phase can reference resources created in an earlier one via [context interpolation](#context-interpolation-and-enrichment).

| Phase | Resource type | Folder | Wrapped module |
| --- | --- | --- | --- |
| 1 | Reserved IP addresses | `net-address` | [net-address](../net-address/) |
| 1 | Service accounts | `service-accounts` | [iam-service-account](../iam-service-account/) |
| 2 | Artifact Registry repositories | `artifact-registry` | [artifact-registry](../artifact-registry/) |
| 2 | BigQuery datasets | `bigquery` | [bigquery-dataset](../bigquery-dataset/) |
| 2 | GCS buckets | `gcs` | [gcs](../gcs/) |
| 2 | Pub/Sub topics | `pubsub` | [pubsub](../pubsub/) |
| 2 | Secret Manager secrets | `secret-manager` | [secret-manager](../secret-manager/) |
| 3 | Cloud Run services, jobs and worker pools | `cloud-run` | [cloud-run-v2](../cloud-run-v2/) |
| 3 | Cloud SQL instances | `cloudsql` | [cloudsql-instance](../cloudsql-instance/) |
| 3 | Compute instances | `compute-vm` | [compute-vm](../compute-vm/) |
| 4 | Internal application load balancers | `net-lb-app-int` | [net-lb-app-int](../net-lb-app-int/) |
| 4 | Internal passthrough network load balancers | `net-lb-int` | [net-lb-int](../net-lb-int/) |

Service accounts follow the same two-pass pattern used in the project factory: they are first created together with their IAM bindings on external resources (projects, folders, buckets, etc.), then IAM bindings on the service accounts themselves are applied in a second pass, so that service accounts can reference each other.

Artifact Registry repositories are also created in two passes: standard and remote repositories first, then virtual repositories, so that the latter can reference the former as upstreams via `$artifact_registries:NAME`. Remote repositories can reference secrets managed by the factory for upstream credentials via `$secrets:NAME/VERSION`.

The folder for each resource type can be changed via the `factories_config.paths` variable. Paths are relative to `factories_config.basepath` unless they are absolute or start with a dot.

### Context interpolation and enrichment

The `context` variable follows the same conventions as the rest of the modules in this repository, and is passed down to the wrapped modules. Its keys are the union of the keys supported by the wrapped modules, so that any static reference (e.g. `$project_ids:app`, `$networks:prod-spoke`, `$kms_keys:europe`) can be used in the YAML files.

The context is also enriched with the resources managed by this module, which can then be referenced from resources in later phases. Enrichment keys follow the project factory conventions.

| Resource type | Context key | Reference format | Value |
| --- | --- | --- | --- |
| Reserved IP addresses | `addresses` | `$addresses:NAME` | IP address |
| Service accounts | `iam_principals` | `$iam_principals:service_accounts/NAME` | IAM email |
| Service accounts | `service_account_ids` | `$service_account_ids:service_accounts/NAME` | Fully qualified id |
| Artifact Registry | `artifact_registries` | `$artifact_registries:NAME` | Fully qualified id |
| BigQuery datasets | `bigquery_datasets` | `$bigquery_datasets:NAME` | Fully qualified id |
| GCS buckets | `storage_buckets` | `$storage_buckets:NAME` | Bucket name |
| Pub/Sub topics | `pubsub_topics` | `$pubsub_topics:NAME` | Fully qualified id |
| Secret Manager | `secrets` | `$secrets:NAME`, `$secrets:NAME/VERSION` | Secret or version id |
| Compute instances | `instance_groups` | `$instance_groups:NAME` | Unmanaged instance group self link, when `group` is set |

The enriched context is available in the `context` output for use in downstream modules or stages.

Interpolation only happens where the wrapped module supports it: refer to each module's `context` variable and documentation to check which attributes are interpolated.

### Resource names

Resource names are derived from file names, and can be overridden via the `name` attribute (`id` for BigQuery datasets). Overriding is needed when the resource name constraints do not allow the file name to be used verbatim, for example for BigQuery dataset ids which cannot contain hyphens, or service account ids which need to be at least six characters long. The file name is always used as the key for outputs and context references.

### Secret Manager and reserved addresses

The Secret Manager and reserved addresses modules manage multiple resources via maps, and this module exposes the same interface: each YAML file in the `secret-manager` and `net-address` folders maps to one module instance, and can define several secrets or addresses. Names must be unique across files as they are merged in the `secrets` and `addresses` context keys.

## Example

```hcl
module "app" {
  source = "./fabric/modules/application-factory"
  factories_config = {
    basepath = "data"
  }
  context = {
    locations = {
      primary = "europe-west1"
    }
    networks = {
      app-vpc = "projects/net-project/global/networks/app-vpc"
    }
    project_ids = {
      app-project = "my-app-prj"
    }
    subnets = {
      app-subnet   = "projects/net-project/regions/europe-west1/subnetworks/app-subnet"
      proxy-subnet = "projects/net-project/regions/europe-west1/subnetworks/proxy-subnet"
    }
  }
}
# tftest modules=16 resources=42 files=addresses,sa-app,sa-ci,gcs,pubsub,bq,secrets,ar,vm,run,sql,lb-int,lb-app-int
```

```yaml
# Reserved addresses for the application load balancers.
# Address names are used as keys in the addresses context.

project_id: $project_ids:app-project
internal_addresses:
  app-lb:
    region: $locations:primary
    subnetwork: $subnets:app-subnet
    address: 10.0.0.10
  app-http-lb:
    region: $locations:primary
    subnetwork: $subnets:app-subnet
    address: 10.0.0.11
# tftest-file id=addresses path=data/net-address/app-addresses.yaml schema=net-address.schema.json
```

```yaml
# Service account for the main application workload.
# Resource name "app-sa" is derived from the filename.

project_id: $project_ids:app-project
display_name: Application service account
description: Main SA for the application workload

iam:
  roles/iam.serviceAccountTokenCreator:
    - $iam_principals:service_accounts/ci-sa

iam_project_roles:
  $project_ids:app-project:
    - roles/storage.objectViewer
    - roles/pubsub.publisher
# tftest-file id=sa-app path=data/service-accounts/app-sa.yaml schema=service-account.schema.json
```

```yaml
# CI/CD service account used by automation pipelines.
# Resource name is overridden as service account ids need at least 6 chars.

project_id: $project_ids:app-project
name: app-ci-sa
display_name: CI/CD service account

iam_project_roles:
  $project_ids:app-project:
    - roles/cloudbuild.builds.builder

# grant roles on other service accounts managed by the factory
iam_sa_roles:
  $service_account_ids:service_accounts/app-sa:
    - roles/iam.serviceAccountUser
# tftest-file id=sa-ci path=data/service-accounts/ci-sa.yaml schema=service-account.schema.json
```

```yaml
# Bucket for application data storage.

project_id: $project_ids:app-project
location: $locations:primary
storage_class: STANDARD
versioning: true
labels:
  environment: dev
  team: platform
uniform_bucket_level_access: true
lifecycle_rules:
  archive-old:
    action:
      type: SetStorageClass
      storage_class: NEARLINE
    condition:
      age: 30
iam:
  roles/storage.objectViewer:
    - $iam_principals:service_accounts/app-sa
# tftest-file id=gcs path=data/gcs/app-data.yaml schema=gcs.schema.json
```

```yaml
# Topic for application events.

project_id: $project_ids:app-project
labels:
  environment: dev
message_retention_duration: 86400s
subscriptions:
  app-events-sub:
    ack_deadline_seconds: 30
    message_retention_duration: 604800s
    retry_policy:
      minimum_backoff: 10
      maximum_backoff: 600
  app-events-bq:
    bigquery:
      table: my-app-prj.app_dataset.events
      write_metadata: true
# tftest-file id=pubsub path=data/pubsub/app-events.yaml schema=pubsub.schema.json
```

```yaml
# Dataset for application analytics.
# Resource id is overridden as dataset ids cannot contain hyphens.

id: app_dataset
project_id: $project_ids:app-project
location: $locations:primary
description: Application analytics dataset
labels:
  environment: dev
options:
  default_table_expiration_ms: 2592000000
  delete_contents_on_destroy: true
tables:
  events:
    description: Application events table
    schema: |
      [
        {"name": "event_id", "type": "STRING", "mode": "REQUIRED"},
        {"name": "timestamp", "type": "TIMESTAMP", "mode": "REQUIRED"},
        {"name": "payload", "type": "JSON", "mode": "NULLABLE"}
      ]
    partitioning:
      time:
        type: DAY
        field: timestamp
    options:
      clustering:
        - event_id
views:
  recent_events:
    query: "SELECT * FROM `events` WHERE timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)"
    description: Events from the last 7 days
iam:
  roles/bigquery.dataViewer:
    - $iam_principals:service_accounts/app-sa
# tftest-file id=bq path=data/bigquery/app-dataset.yaml schema=bigquery.schema.json
```

```yaml
# Secrets for the application.

project_id: $project_ids:app-project
secrets:
  db-password:
    labels:
      environment: dev
    iam:
      roles/secretmanager.secretAccessor:
        - $iam_principals:service_accounts/app-sa
    versions:
      latest:
        data: changeme
  api-key:
    labels:
      environment: dev
    iam:
      roles/secretmanager.secretAccessor:
        - $iam_principals:service_accounts/app-sa
        - $iam_principals:service_accounts/ci-sa
# tftest-file id=secrets path=data/secret-manager/app-secrets.yaml schema=secret-manager.schema.json
```

```yaml
# Docker registry for application container images.

project_id: $project_ids:app-project
location: $locations:primary
description: Application container images
format:
  docker:
    standard:
      immutable_tags: true
labels:
  environment: dev
iam:
  roles/artifactregistry.reader:
    - $iam_principals:service_accounts/app-sa
  roles/artifactregistry.writer:
    - $iam_principals:service_accounts/ci-sa
# tftest-file id=ar path=data/artifact-registry/app-docker.yaml schema=artifact-registry.schema.json
```

```yaml
# Main application server VM.

project_id: $project_ids:app-project
zone: europe-west1-b
machine_type: e2-medium
labels:
  environment: dev
  role: app-server
boot_disk:
  source:
    image: projects/debian-cloud/global/images/family/debian-12
  initialize_params:
    size: 20
    type: pd-balanced
network_interfaces:
  - network: $networks:app-vpc
    subnetwork: $subnets:app-subnet
service_account:
  email: $iam_principals:service_accounts/app-sa
  scopes:
    - https://www.googleapis.com/auth/cloud-platform
shielded_config:
  enable_secure_boot: true
  enable_vtpm: true
  enable_integrity_monitoring: true
tags:
  - app
  - http-server
group:
  named_ports:
    http: 8080
# tftest-file id=vm path=data/compute-vm/app-server.yaml schema=compute-vm.schema.json
```

```yaml
# Cloud Run service for the application API.

project_id: $project_ids:app-project
region: $locations:primary
labels:
  environment: dev
containers:
  api:
    image: europe-west1-docker.pkg.dev/my-app-prj/app-docker/api:latest
    ports:
      http1:
        container_port: 8080
    env:
      DB_NAME: app
    env_from_key:
      DB_PASSWORD:
        secret: db-password
        version: latest
service_account_config:
  create: false
  email: $iam_principals:service_accounts/app-sa
revision:
  vpc_access:
    subnet: $subnets:app-subnet
    egress: PRIVATE_RANGES_ONLY
service_config:
  ingress: INGRESS_TRAFFIC_INTERNAL_ONLY
iam:
  roles/run.invoker:
    - $iam_principals:service_accounts/ci-sa
# tftest-file id=run path=data/cloud-run/app-api.yaml schema=cloud-run.schema.json
```

```yaml
# PostgreSQL database for the application.

project_id: $project_ids:app-project
database_version: POSTGRES_15
tier: db-custom-2-8192
region: europe-west1
availability_type: REGIONAL
disk_size: 20
disk_type: PD_SSD
databases:
  - app
  - app_test
backup_configuration:
  enabled: true
  point_in_time_recovery_enabled: true
  retention_count: 14
network_config:
  connectivity:
    psa_config:
      private_network: $networks:app-vpc
gcp_deletion_protection: false
terraform_deletion_protection: false
flags:
  log_min_duration_statement: "1000"
users:
  app-user:
    type: CLOUD_IAM_SERVICE_ACCOUNT
ssl:
  mode: ENCRYPTED_ONLY
# tftest-file id=sql path=data/cloudsql/app-db.yaml schema=cloudsql.schema.json
```

```yaml
# Internal TCP load balancer for application traffic.

project_id: $project_ids:app-project
region: europe-west1
vpc_config:
  network: $networks:app-vpc
  subnetwork: $subnets:app-subnet
backends:
  - group: $instance_groups:app-server
forwarding_rules_config:
  "":
    address: $addresses:app-lb
    ports:
      - "8080"
    protocol: TCP
health_check_config:
  tcp:
    port: 8080
# tftest-file id=lb-int path=data/net-lb-int/app-lb.yaml schema=net-lb-int.schema.json
```

```yaml
# Internal HTTP load balancer for application traffic.

project_id: $project_ids:app-project
region: europe-west1
protocol: HTTP
address: $addresses:app-http-lb
vpc_config:
  network: $networks:app-vpc
  subnetwork: $subnets:proxy-subnet
backend_service_configs:
  default:
    backends:
      - group: $instance_groups:app-server
    health_checks:
      - default
    port_name: http
health_check_configs:
  default:
    http:
      port: 8080
      request_path: /healthz
urlmap_config:
  default_service: default
# tftest-file id=lb-app-int path=data/net-lb-app-int/app-http-lb.yaml schema=net-lb-app-int.schema.json
```

<!-- TFDOC OPTS files:1 -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules |
|---|---|---|
| [artifact-registry.tf](./artifact-registry.tf) | Phase 2: Artifact Registry. | <code>artifact-registry</code> |
| [bigquery.tf](./bigquery.tf) | Phase 2: BigQuery datasets. | <code>bigquery-dataset</code> |
| [cloud-run.tf](./cloud-run.tf) | Phase 3: Cloud Run services, jobs and worker pools. | <code>cloud-run-v2</code> |
| [cloudsql.tf](./cloudsql.tf) | Phase 3: Cloud SQL instances. | <code>cloudsql-instance</code> |
| [compute-vm.tf](./compute-vm.tf) | Phase 3: Compute VMs. | <code>compute-vm</code> |
| [gcs.tf](./gcs.tf) | Phase 2: GCS buckets. | <code>gcs</code> |
| [main.tf](./main.tf) | Context locals and path resolution. |  |
| [net-address.tf](./net-address.tf) | Phase 1: Reserved IP addresses. | <code>net-address</code> |
| [net-lb-app-int.tf](./net-lb-app-int.tf) | Phase 4: Internal application load balancers. | <code>net-lb-app-int</code> |
| [net-lb-int.tf](./net-lb-int.tf) | Phase 4: Internal passthrough network load balancers. | <code>net-lb-int</code> |
| [outputs.tf](./outputs.tf) | Module outputs. |  |
| [pubsub.tf](./pubsub.tf) | Phase 2: Pub/Sub topics. | <code>pubsub</code> |
| [secret-manager.tf](./secret-manager.tf) | Phase 2: Secret Manager. | <code>secret-manager</code> |
| [service-accounts.tf](./service-accounts.tf) | Phase 1: Service accounts (create + IAM split). | <code>iam-service-account</code> |
| [variables.tf](./variables.tf) | Module variables. |  |
| [versions.tf](./versions.tf) | Version pins. |  |

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [factories_config](variables.tf#L49) | Path configuration for YAML resource description data files. Paths are relative to basepath unless absolute or starting with a dot. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [context](variables.tf#L17) | Context-specific interpolations. Keys are the union of those supported by the wrapped modules, and are enriched with factory-managed resources. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [artifact_registry](outputs.tf#L19) | Artifact Registry repositories. |  |
| [bigquery](outputs.tf#L32) | BigQuery datasets. |  |
| [cloud_run](outputs.tf#L47) | Cloud Run services, jobs and worker pools. |  |
| [cloudsql](outputs.tf#L61) | Cloud SQL instances. |  |
| [compute_vm](outputs.tf#L83) | Compute instances. |  |
| [context](outputs.tf#L100) | Context enriched with factory-managed resources, for use in downstream modules. |  |
| [gcs](outputs.tf#L105) | GCS buckets. |  |
| [net_address](outputs.tf#L116) | Reserved IP addresses, keyed by address name. |  |
| [net_lb_app_int](outputs.tf#L121) | Internal application load balancers. |  |
| [net_lb_int](outputs.tf#L138) | Internal passthrough network load balancers. |  |
| [pubsub](outputs.tf#L153) | Pub/Sub topics. |  |
| [secret_manager](outputs.tf#L163) | Secret Manager secrets. |  |
| [service_accounts](outputs.tf#L173) | Service accounts. |  |
<!-- END TFDOC -->
