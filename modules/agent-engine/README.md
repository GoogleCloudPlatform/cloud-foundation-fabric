# Agent Engine Module

The module creates Agent Engine and related dependencies.

- It supports both source based deployments (aka in-line deployment) and serialized object deployment (aka pickle deployment).
- For serialized object deployment, it optionally creates a GCS storage bucket or can use an existing one and loads on it all your dependencies (`pickle`, `dependencies.tar.gz`, `requirements.txt`).
- Manages custom service accounts lifecycle.

<!-- BEGIN TOC -->
- [Source based deployment](#source-based-deployment)
  - [Create the tar.gz package](#create-the-targz-package)
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
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Source based deployment

The source based deployment is the newest, most efficient and easiest way to deploy your agents.

### Create the tar.gz package

First, create a *tar.gz* file with these files:

- The source Python file defining your agent, called `agent.py`.
- The `requirements.txt` file.

By default, the module expects the `tar.gz` file to be in the `src` subfolder and to be called `source.tar.gz`.

This is an example of an `agent.py` file for ADK:

```python
from google.adk.agents import LlmAgent
from vertexai.agent_engines import AdkApp

def get_exchange_rate(
    currency_from: str = "USD",
    currency_to: str = "EUR",
    currency_date: str = "latest",
):
    import requests
    response = requests.get(
        f"https://api.frankfurter.app/{currency_date}",
        params={"from": currency_from, "to": currency_to},
    )
    return response.json()

root_agent = LlmAgent(
    model="gemini-2.5-flash",
    instruction="You are a helpful assistant",
    name='currency_exchange_agent',
    tools=[get_exchange_rate],
)

agent = AdkApp(agent=root_agent)
```

### Minimal deployment

You can now deploy the agent.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_files = {
    source_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }
}
# tftest inventory=minimal.yaml
```

You can change the name of the tar.gz package, of the requirement file, the name of the Python file and the name of the agent function by using the `deployment_files.source_config` variable.

You can also provide custom build arguments for the container image by using the `deployment_files.source_config.image_spec` variable.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_files = {
    source_config = {
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

  deployment_files = {
    package_config = {
      dependencies_path = "assets/src/dependencies.tar.gz"
      pickle_path       = "assets/src/pickle.pkl"
      requirements_path = "assets/src/requirements.txt"
    }
    source_config = null
  }
}
# tftest inventory=minimal-pickle.yaml
```

You may want to upload your files on the GCS bucket outside Terrafrom.
In this example, the module expects your package config files to be already present in the GCS bucket.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  bucket_config = {
    create = false
  }

  deployment_files = {
    package_config = {
      are_paths_local   = false
      dependencies_path = "dependencies.tar.gz"
      pickle_path       = "pickle.pkl"
      requirements_path = "requirements.txt"
    }
    source_config = null
  }
}
# tftest inventory=pickle-gcs.yaml
```

### Unmanaged deployments

By default, this module tracks and controls code updates. This means you can only the agent code via Terraform.
Anyway, you may want to delegate this operation to third-party tools, outside Terraform.
To do so, deploy the first revision of your code by using the module (this can even be a hello world) and set `var.managed` to `false`.

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

  deployment_files = {
    source_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }
}
# tftest inventory=unmanaged.yaml
```

## Service accounts

By default, the module creates a dedicated service account for your agent and grants it the roles needed to deploy the agent. The default roles are defined in `var.service_account_config.roles`. You can add more roles, as needed.

You can also use the default Agent Engine (Reasoning Engine) service agent.
In this case, it will be your responsibility to grant any other role needed to the service agent service account.
At the moment, you'll need at least to grant to it the `roles/viewer` role.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  service_account_config = {
    create = false
  }

  deployment_files = {
    source_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }
}
# tftest inventory=sa-default.yaml
```

Alternatively, you can use an existing service account.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  service_account_config = {
    create = false
    email  = "my-sa@${var.project_id}.iam.gserviceaccount.com"
  }

  deployment_files = {
    source_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }
}
# tftest inventory=sa-custom.yaml
```

## Private networking: setup PSC-I

Your agent can privately access resources in your VPC. This is done with Private Service Connect Interface (PSC-I).

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_files = {
    source_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }

  networking_config = {
    network_attachment_id = google_compute_network_attachment.network_attachment.id
    dns_peering_configs = {
      "example.com" = {
        target_network_name = "my-vpc-1"
      }
      "my-company.local" = {
        target_network_name = "my-vpc-2"
        target_project_id   = "my-other-project"
      }
    }
  }
}

resource "google_compute_network_attachment" "network_attachment" {
  name                  = "network-attachment"
  project               = var.project_id
  region                = var.region
  description           = "Network attachment for Agent Engine PSC-I"
  connection_preference = "ACCEPT_MANUAL"
  subnetworks           = [var.subnet.self_link]

  # Agent Engine SA automatically populates this when PSC-I is active.
  # It adds the tenant project id.
  lifecycle {
    ignore_changes = [producer_accept_lists]
  }
}
# tftest inventory=psc-i.yaml
```

## Specify an encryption key

You can optionally specify an existing encryption key, created in KMS.

To use KMS keys you'll need to grant the AI Platform Service Agent (`service-YOUR_PROJECT_NUMBER@gcp-sa-aiplatform-re.iam.gserviceaccount.com`) the `roles/cloudkms.cryptoKeyEncrypterDecrypter` role on the key.

```hcl
module "agent_engine" {
  source         = "./fabric/modules/agent-engine"
  name           = "my-agent"
  project_id     = var.project_id
  region         = var.region
  encryption_key = "projects/${var.project_id}/locations/${var.region}/keyRings/my-keyring/cryptoKeys/my-key"

  agent_engine_config = {
    agent_framework = "google-adk"
  }

  deployment_files = {
    source_config = {
      source_path = "assets/src/source.tar.gz"
    }
  }
}
# tftest inventory=encryption.yaml
```

## Define environment variables and use secrets

You can define environment variables and load existing secrets as environment variables into your agent.

```hcl
module "agent_engine" {
  source     = "./fabric/modules/agent-engine"
  name       = "my-agent"
  project_id = var.project_id
  region     = var.region

  agent_engine_config = {
    agent_framework = "google-adk"

    environment_variables = {
      FOO = "my-foo-variable"
    }
    secret_environment_variables = {
      BAR = {
        secret_id = "projects/YOUR_PROJECT_NUMBER/secrets/my-bar-secret"
      }
    }
  }

  deployment_files = {
    source_config = {
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

  deployment_files = {
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

  deployment_files = {
    source_config = {
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
# tftest skip
```

## Getting values from context

The module allows you to dynamically reference context values for resources created outside this module, through the `context` variable. This includes the definition of custom roles, iam_principals, locations, kms_keys, models and project ids.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L147) | The name of the agent. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L166) | The id of the project where to deploy the agent. | <code>string</code> | ✓ |  |
| [region](variables.tf#L172) | The region where to deploy the agent. | <code>string</code> | ✓ |  |
| [agent_engine_config](variables.tf#L17) | The agent configuration. Supported values for agent_framework: 'google-adk', 'langchain', 'langgraph', 'ag2', 'llama-index', 'custom'. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [bucket_config](variables.tf#L41) | The GCS bucket configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L53) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [deployment_files](variables.tf#L67) | The to source files path and names. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |
| [description](variables.tf#L104) | The Agent Engine description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [encryption_key](variables.tf#L111) | The full resource name of the Cloud KMS CryptoKey. | <code>string</code> |  | <code>null</code> |
| [managed](variables.tf#L117) | Whether the Terraform module should control the code updates. | <code>bool</code> |  | <code>true</code> |
| [memory_bank_config](variables.tf#L124) | Configuration for the memory bank. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [networking_config](variables.tf#L153) | Networking configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [service_account_config](variables-serviceaccount.tf#L18) | Service account configurations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [agent](outputs.tf#L17) | The Agent Engine object. |  |
| [id](outputs.tf#L22) | Fully qualified Agent Engine id. |  |
| [service_account](outputs.tf#L27) | Service account resource. |  |
<!-- END TFDOC -->
