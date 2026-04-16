# Agent Engine Module

The module creates Agent Engine and related dependencies.

- It supports both source based deployments (aka in-line deployment) and serialized object deployment (aka pickle deployment).
- For serialized object deployment, the module creates a GCS bucket to store the pickled object and related dependencies.
- It supports Customer Managed Encryption Keys (CMEK) to encrypt both the reasoning engine and the GCS bucket.
- It provides support for both managed and unmanaged (Terraform doesn't track updates to code) deployments.
- It provides support for VPC-SC (via PSC-I).
- It provides support for custom and default service accounts.
- It provides support for environment variables and secrets from Secret Manager.
- It supports both Python-based and container-based deployments.

## TOC

<!-- BEGIN TOC -->
- [TOC](#toc)
- [Minimal deployment](#minimal-deployment)
- [Serialized Object Deployment](#serialized-object-deployment)
- [Unmanaged deployments](#unmanaged-deployments)
- [Service accounts](#service-accounts)
- [Private networking: setup PSC-I](#private-networking-setup-psc-i)
- [Specify an encryption key](#specify-an-encryption-key)
- [Define environment variables and use secrets](#define-environment-variables-and-use-secrets)
- [Container-based deployment](#container-based-deployment)
- [Memory Bank](#memory-bank)
- [Getting values from context](#getting-values-from-context)
- [Disable deletion protection](#disable-deletion-protection)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Minimal deployment

This example shows how to deploy an agent engine with minimal configuration, using source code from a local path.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    source_files_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }
}
# tftest inventory=minimal.yaml
```

You can change the name of the tar.gz package, of the requirement file, the name of the Python file and the name of the agent function by using the `deployment_config.source_files_config` variable.

You can also provide custom build arguments for the container image by using the `deployment_config.source_files_config.image_spec` variable.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    source_files_config = {
      source_path = "assets/src/source.tar.gz"
      image_spec = {
        build_args = {
          "ENV" = "production"
        }
      }
    }
  }
}
# tftest inventory=image-spec.yaml
```

## Serialized Object Deployment

You can also manually serialize your agent by using the [cloudpickle library](https://github.com/cloudpipe/cloudpickle) and pass the `pickle.pkl`, `dependencies.tar.gz` and `requirements.txt` files to the module.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    package_config = {
      pickle_path       = "assets/src/pickle.pkl"
      dependencies_path = "assets/src/dependencies.tar.gz"
      requirements_path = "assets/src/requirements.txt"
    }
  }
}
# tftest inventory=minimal-pickle.yaml
```

If the files are already in a GCS bucket, you can pass the GCS URIs to the module.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    package_config = {
      are_paths_local   = false
      pickle_path       = "gs://my-bucket/pickle.pkl"
      dependencies_path = "gs://my-bucket/dependencies.tar.gz"
      requirements_path = "gs://my-bucket/requirements.txt"
    }
  }
}
# tftest inventory=pickle-gcs.yaml
```

## Unmanaged deployments

If you want to use the module just to bootstrap the infrastructure and then manage the code updates yourself, you can set the `managed` variable to `false`.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region
  managed    = false

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    source_files_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }
}
# tftest inventory=unmanaged.yaml
```

## Service accounts

You can choose to use a custom service account or let the module create one for you.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    source_files_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }
}
# tftest inventory=sa-default.yaml
```

Using a custom service account.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    source_files_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }

  service_account_config = {
    create = false
    email  = "my-agent@project-id.iam.gserviceaccount.com"
  }
}
# tftest inventory=sa-custom.yaml
```

## Private networking: setup PSC-I

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    source_files_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }

  networking_config = {
    network_attachment_id = "projects/project-id/regions/europe-west8/networkAttachments/my-nat"
    dns_peering_configs = {
      "googleapis.com." = {
        target_network_name = "my-network"
      }
    }
  }
}
# tftest inventory=psc-i.yaml
```

## Specify an encryption key

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    source_files_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }

  encryption_key = "projects/project-id/locations/europe-west8/keyRings/my-keyring/cryptoKeys/my-key"
}
# tftest inventory=encryption.yaml
```

## Define environment variables and use secrets

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
    environment_variables = {
      FOO = "bar"
    }
    secret_environment_variables = {
      MY_SECRET = {
        secret_id = "projects/project-id/secrets/my-secret"
      }
    }
  }

  deployment_config = {
    source_files_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }
}
# tftest inventory=environment.yaml
```

## Container-based deployment

You can deploy your agent as a custom Docker image.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    environment_variables = {
      FOO = "bar"
    }
  }

  deployment_config = {
    container_config = {
      image_uri = "us-central1-docker.pkg.dev/my-project/my-repo/my-image:latest"
    }
  }
}
# tftest inventory=container.yaml
```

## Memory Bank

You can optionally configure a Memory Bank to provide long-term persistent memory for your agent.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    source_files_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }

  memory_bank_config = {
    disable_memory_revisions = false
    generation_config = {
      model = "projects/my-project/locations/us-central1/publishers/google/models/gemini-2.0-flash-001"
    }
    similarity_search_config = {
      embedding_model = "projects/my-project/locations/us-central1/publishers/google/models/text-embedding-005"
    }
    ttl_config = {
      default_ttl = "2592000s" # 30 days
    }
  }
}
```

## Getting values from context

The module allows you to dynamically reference context values for resources created outside this module, through the `context` variable. This includes the definition of custom roles, iam_principals, locations, networks, psc_network_attachments, kms_keys, models and project ids.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = "$project_ids:main-project"
  region     = "$locations:primary"
  agent_engine_config = {
    agent_framework = "google-adk"
  }
  deployment_config = {
    source_files_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }
  networking_config = {
    network_attachment_id = "$psc_network_attachments:primary"
    dns_peering_configs = {
      "example.com" = {
        target_network_name = "$networks:vpc-1"
      }
      "my-company.local" = {
        target_network_name = "$networks:vpc-2"
        target_project_id   = "$project_ids:dns-project"
      }
    }
  }
  service_account_config = {
    create = false
    email  = "$iam_principals:my-custom-sa"
  }
  context = {
    iam_principals = {
      my-custom-sa = "my-sa@$test-project-1.iam.gserviceaccount.com"
    }
    locations = {
      primary = "europe-west1"
    }
    networks = {
      vpc-1 = "my-vpc-1"
      vpc-2 = "my-vpc-2"
    }
    project_ids = {
      main-project = "test-project-1"
      dns-project  = "company-dns-project"
    }
    psc_network_attachments = {
      primary = "projects/test-project-1/regions/europe-west1/networkAttachments/core-service"
    }
  }
}
# tftest inventory=context.yaml
```

## Disable deletion protection

By default you can't neither delete your agent if it has session or your GCS bucket if it has files inside. For testing, you can anyway force the deletion of these resources:

```hcl
module "agent_engine" {
  source                     = "./fabric/modules/agent-engine"
  name                       = "my-agent"
  project_id                 = var.project_id
  region                     = var.region
  enable_deletion_protection = false

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_config = {
    package_config = {
      pickle_path       = "assets/src/pickle.pkl"
      dependencies_path = "assets/src/dependencies.tar.gz"
      requirements_path = "assets/src/requirements.txt"
    }
  }
}
# tftest inventory=deletion-protection.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L187) | The name of the agent. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L206) | The id of the project where to deploy the agent. | <code>string</code> | ✓ |  |
| [region](variables.tf#L212) | The region where to deploy the agent. | <code>string</code> | ✓ |  |
| [agent_engine_config](variables.tf#L17) | The agent configuration. Supported values for agent_framework: 'google-adk', 'langchain', 'langgraph', 'ag2', 'llama-index', 'custom'. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [bucket_config](variables.tf#L50) | The GCS bucket configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L61) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [deployment_config](variables.tf#L77) | The deployment configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L137) | The Agent Engine description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [enable_deletion_protection](variables.tf#L144) | Whether deletion protection should be enabled. | <code>bool</code> |  | <code>true</code> |
| [encryption_key](variables.tf#L151) | The full resource name of the Cloud KMS CryptoKey. | <code>string</code> |  | <code>null</code> |
| [managed](variables.tf#L157) | Whether the Terraform module should control the code updates. | <code>bool</code> |  | <code>true</code> |
| [memory_bank_config](variables.tf#L164) | Configuration for the memory bank. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [networking_config](variables.tf#L193) | Networking configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [service_account_config](variables-serviceaccount.tf#L18) | Service account configurations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [agent](outputs.tf#L17) | The Agent Engine object. |  |
| [id](outputs.tf#L22) | Fully qualified Agent Engine id. |  |
| [service_account](outputs.tf#L27) | Service account resource. |  |
<!-- END TFDOC -->
