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
- [Specify an encryption key](#specify-an-encryption-key)
- [Define environment variables and use secrets](#define-environment-variables-and-use-secrets)
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
# tftest inventory=minimal-pickle.yaml
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

## Getting values from context

The module allows you to dynamically reference context values for resources created outside this module, through the `context` variable. This includes the definition of custom roles, iam_principals, locations, kms_keys and project ids.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [agent_engine_config](variables.tf#L17) | The agent configuration. | <code title="object&#40;&#123;&#10;  agent_framework       &#61; string&#10;  class_methods         &#61; optional&#40;list&#40;any&#41;, &#91;&#93;&#41;&#10;  container_concurrency &#61; optional&#40;number&#41;&#10;  environment_variables &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  max_instances         &#61; optional&#40;number&#41;&#10;  min_instances         &#61; optional&#40;number&#41;&#10;  python_version        &#61; optional&#40;string, &#34;3.12&#34;&#41;&#10;  resource_limits &#61; optional&#40;object&#40;&#123;&#10;    cpu    &#61; string&#10;    memory &#61; string&#10;  &#125;&#41;&#41;&#10;  secret_environment_variables &#61; optional&#40;map&#40;object&#40;&#123;&#10;    secret_id &#61; string&#10;    version   &#61; optional&#40;string, &#34;latest&#34;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L122) | The name of the agent. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L128) | The id of the project where to deploy the agent. | <code>string</code> | ✓ |  |
| [region](variables.tf#L134) | The region where to deploy the agent. | <code>string</code> | ✓ |  |
| [bucket_config](variables.tf#L40) | The GCS bucket configuration. | <code title="object&#40;&#123;&#10;  create                      &#61; optional&#40;bool, true&#41;&#10;  deletion_protection         &#61; optional&#40;bool, true&#41;&#10;  name                        &#61; optional&#40;string&#41;&#10;  uniform_bucket_level_access &#61; optional&#40;bool, true&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L52) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  custom_roles   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  kms_keys       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [deployment_files](variables.tf#L65) | The to source files path and names. | <code title="object&#40;&#123;&#10;  package_config &#61; optional&#40;object&#40;&#123;&#10;    are_paths_local   &#61; optional&#40;bool, true&#41;&#10;    dependencies_path &#61; optional&#40;string, &#34;.&#47;src&#47;dependencies.tar.gz&#34;&#41;&#10;    pickle_path       &#61; optional&#40;string, &#34;.&#47;src&#47;pickle.pkl&#34;&#41;&#10;    requirements_path &#61; optional&#40;string, &#34;.&#47;src&#47;requirements.txt&#34;&#41;&#10;  &#125;&#41;, null&#41;&#10;  source_config &#61; optional&#40;object&#40;&#123;&#10;    entrypoint_module &#61; optional&#40;string, &#34;agent&#34;&#41;&#10;    entrypoint_object &#61; optional&#40;string, &#34;agent&#34;&#41;&#10;    requirements_path &#61; optional&#40;string, &#34;requirements.txt&#34;&#41;&#10;    source_path       &#61; optional&#40;string, &#34;.&#47;src&#47;source.tar.gz&#34;&#41;&#10;  &#125;&#41;, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  package_config &#61; null&#10;  source_config  &#61; &#123;&#125;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [description](variables.tf#L102) | The Agent Engine description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [encryption_key](variables.tf#L109) | The full resource name of the Cloud KMS CryptoKey. | <code>string</code> |  | <code>null</code> |
| [managed](variables.tf#L115) | Whether the Terraform module should control the code updates. | <code>bool</code> |  | <code>true</code> |
| [service_account_config](variables-serviceaccount.tf#L18) | Service account configurations. | <code title="object&#40;&#123;&#10;  create       &#61; optional&#40;bool, true&#41;&#10;  display_name &#61; optional&#40;string&#41;&#10;  email        &#61; optional&#40;string&#41;&#10;  name         &#61; optional&#40;string&#41;&#10;  roles &#61; optional&#40;list&#40;string&#41;, &#91;&#10;    &#34;roles&#47;aiplatform.user&#34;,&#10;    &#34;roles&#47;storage.objectViewer&#34;,&#10;    &#34;roles&#47;viewer&#34;&#10;  &#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [agent](outputs.tf#L17) | The Agent Engine object. |  |
| [id](outputs.tf#L22) | Fully qualified Agent Engine id. |  |
| [service_account](outputs.tf#L27) | Service account resource. |  |
<!-- END TFDOC -->
