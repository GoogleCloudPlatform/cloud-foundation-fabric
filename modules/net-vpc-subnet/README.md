# VPC Subnet Module

This module creates a Google Cloud VPC subnet with optional IAM bindings, following the same pattern as the GCS module.

## Features

- **Context interpolation** for project_id, network, and region using `$` prefix (e.g., `$project_ids:net-dev`, `$vpc_ids:dev`)
- **Secondary IP ranges** support for GKE pods and services
- **VPC flow logs** configuration
- **IAM bindings** with support for authoritative and additive bindings
- **Conditional IAM** with templatestring support

## Example Usage

### Basic Subnet

```hcl
module "subnet" {
  source = "./modules/net-vpc-subnet"

  project_id    = "$project_ids:net-dev"
  name          = "dev-subnet-1"
  region        = "us-central1"
  network       = "$vpc_ids:dev"
  ip_cidr_range = "10.0.1.0/24"

  context = {
    project_ids = { "net-dev" = "my-project-123" }
    vpc_ids     = { "dev" = "projects/my-project-123/global/networks/dev-vpc" }
  }
}
```

### Subnet with Secondary IP Ranges (for GKE)

```hcl
module "gke_subnet" {
  source = "./modules/net-vpc-subnet"

  project_id    = "$project_ids:net-dev"
  name          = "gke-subnet"
  region        = "us-central1"
  network       = "$vpc_ids:dev"
  ip_cidr_range = "10.0.2.0/24"

  secondary_ip_ranges = {
    pods = {
      ip_cidr_range = "100.64.0.0/16"
    }
    services = {
      ip_cidr_range = "100.64.1.0/24"
    }
  }

  context = local.context
}
```

### Subnet with Flow Logs

```hcl
module "subnet_with_logs" {
  source = "./modules/net-vpc-subnet"

  project_id       = "my-project-123"
  name             = "monitored-subnet"
  region           = "us-central1"
  network          = "my-vpc"
  ip_cidr_range    = "10.0.3.0/24"
  enable_flow_logs = true

  log_config = {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.8
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
```

### Subnet with IAM Bindings

```hcl
module "subnet_with_iam" {
  source = "./modules/net-vpc-subnet"

  project_id    = "$project_ids:net-dev"
  name          = "shared-subnet"
  region        = "us-central1"
  network       = "$vpc_ids:dev"
  ip_cidr_range = "10.0.4.0/24"

  iam = {
    "roles/compute.networkUser" = [
      "serviceAccount:gke-sa@my-project.iam.gserviceaccount.com"
    ]
  }

  context = local.context
}
```

## Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| project_id | Project ID (supports context interpolation) | string | required |
| name | Subnet name | string | required |
| region | Region (supports context interpolation) | string | required |
| network | VPC network (supports context interpolation) | string | required |
| ip_cidr_range | IP CIDR range | string | required |
| secondary_ip_ranges | Secondary IP ranges map | map(object) | {} |
| enable_flow_logs | Enable VPC flow logs | bool | false |
| private_ip_google_access | Enable private Google access | bool | true |
| iam | IAM bindings in {ROLE => [MEMBERS]} format | map(list(string)) | {} |
| context | Context-specific interpolations | object | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | Subnet fully qualified ID |
| name | Subnet name |
| region | Subnet region |
| self_link | Subnet self link |
| subnet | Full subnet resource |

## Context Interpolation

The module supports context interpolation using `$` prefix:

- `$project_ids:key` - Resolves to project ID from context
- `$vpc_ids:key` - Resolves to VPC network from context
- `$locations:key` - Resolves to region from context
- `$iam_principals:key` - Resolves to IAM principal from context
- `$custom_roles:key` - Resolves to custom role from context