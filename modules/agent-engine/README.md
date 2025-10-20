# Agent Engine Module

The module creates Agent Engine and related dependencies.

- It can automatically generate and update the Pickle file for you, given a source file.
- It optionally creates a GCS storage bucket or can use an existing one and loads on it all your dependencies (`pickle`, `dependencies.tar.gz`, `requirements.txt`)
- Manages the service accounts lifecycle

<!-- BEGIN TOC -->
- [Packaging dependencies](#packaging-dependencies)
- [Minimal deployment](#minimal-deployment)
- [Service accounts](#service-accounts)
- [Specify an encryption key](#specify-an-encryption-key)
- [Define environment variables and use secrets](#define-environment-variables-and-use-secrets)
- [Getting values from context](#getting-values-from-context)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## Packaging dependencies

To deploy an agent, you first need package your dependencies. This consists of a folder with

- The source Python file defining your agent to be pickled (or the equivalent pickle file).
- The `dependencies.tar.gz`.
- The `requirements.txt` file.

By default, the module expects these files to be in an `src` subfolder.

You can decide to **let the module create the pickle file for you**, starting from a source agent file.
In this case, the module expects you to have in `src` a source file called `agent.py` with a variable referencing your agent function definition called `local_agent`.

This is an example of `agent.py` file for ADK:

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

local_agent = AdkApp(agent=root_agent)
```

The [tools/serialize_agent.py](tools/serialize_agent.py) is used to generate the `pickle.pkl` file.
You module needs [these packages](tools/requirements.txt) to work.

If you **already have a pickle file**, the module expects you to have in the `src` subfolder a `pickle.pkl` file.

You can customize these values by using the `source_files` variable.

## Minimal deployment

This example assumes you are providing the [source packages](#packaging-dependencies) (`agent.py`, `dependencies.tar.gz` and `requirements.txt`) in the `src` subfolder. Every time you will change the agent definition, the module will generate the new pickle file for you, will update it on the GCS bucket and will update your agent.

```hcl
module "agent_engine" {
  source          = "./fabric/modules/agent-engine"
  name            = "my-agent"
  project_id      = var.project_id
  agent_framework = "google-adk"
  region          = var.region

  source_files = {
    path = "assets/src/"
  }
}
# tftest inventory=minimal.yaml
```

Alternatively, you can pass a pre-generated `pickle.pkl` file.

```hcl
module "agent_engine" {
  source          = "./fabric/modules/agent-engine"
  name            = "my-agent"
  project_id      = var.project_id
  agent_framework = "google-adk"
  region          = var.region
  generate_pickle = false

  source_files = {
    path = "assets/src/"
  }
}
# tftest inventory=minimal-pickle.yaml
```

## Service accounts

By default, the module creates a dedicated service account for your agent and grants it the roles needed to deploy the agent. The default roles are defined in `var.service_account_config.roles`. You can add more roles, as needed.

You can also use the default Agent Engine (Reasoning Engine) service agent.
In this case, it will be your responsibility to grant any other role needed to the service agent service account.
At the moment, you'll need at least to grant to it the `roles/viewer` role.

```hcl
module "agent_engine" {
  source          = "./fabric/modules/agent-engine"
  name            = "my-agent"
  project_id      = var.project_id
  agent_framework = "google-adk"
  region          = var.region

  service_account_config = {
    create = false
  }

  source_files = {
    path = "assets/src/"
  }
}
# tftest inventory=sa-default.yaml
```

Alternatively, you can use an existing service account.

```hcl
module "agent_engine" {
  source          = "./fabric/modules/agent-engine"
  name            = "my-agent"
  project_id      = var.project_id
  agent_framework = "google-adk"
  region          = var.region

  service_account_config = {
    create = false
    email  = "my-sa@${var.project_id}.iam.gserviceaccount.com"
  }

  source_files = {
    path = "assets/src/"
  }
}
# tftest inventory=sa-custom.yaml
```

## Specify an encryption key

You can optionally specify an existing encryption key, created in KMS.

To use KMS keys you'll need to grant the AI Platform Service Agent (`service-YOUR_PROJECT_NUMBER@gcp-sa-aiplatform-re.iam.gserviceaccount.com`) the `roles/cloudkms.cryptoKeyEncrypterDecrypter` role on the key.

```hcl
module "agent_engine" {
  source          = "./fabric/modules/agent-engine"
  name            = "my-agent"
  project_id      = var.project_id
  agent_framework = "google-adk"
  region          = var.region
  encryption_key  = "projects/${var.project_id}/locations/${var.region}/keyRings/my-keyring/cryptoKeys/my-key"

  source_files = {
    path = "assets/src/"
  }
}
# tftest inventory=encryption.yaml
```

## Define environment variables and use secrets

You can define environment variables and load existing secrets as environment variables into your agent. 

```hcl
module "agent_engine" {
  source          = "./fabric/modules/agent-engine"
  name            = "my-agent"
  project_id      = var.project_id
  agent_framework = "google-adk"
  region          = var.region

  environment_variables = {
    FOO = "my-foo-variable"
  }

  secret_environment_variables = {
    BAR = {
      secret_id = "projects/YOUR_PROJECT_NUMBER/secrets/my-bar-secret"
    }
  }

  source_files = {
    path = "assets/src/"
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
| [agent_engine_config](variables.tf#L17) | The agent configuration. | <code title="object&#40;&#123;&#10;  agent_framework       &#61; string&#10;  class_methods         &#61; optional&#40;list&#40;any&#41;, &#91;&#93;&#41;&#10;  environment_variables &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  python_version        &#61; optional&#40;string, &#34;3.12&#34;&#41;&#10;  secret_environment_variables &#61; optional&#40;map&#40;object&#40;&#123;&#10;    secret_id &#61; string&#10;    version   &#61; optional&#40;string, &#34;latest&#34;&#41;&#10;  &#125;&#41;&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [name](variables.tf#L77) | The name of the agent. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L83) | The id of the project where to deploy the agent. | <code>string</code> | ✓ |  |
| [region](variables.tf#L89) | The region where to deploy the agent. | <code>string</code> | ✓ |  |
| [bucket_config](variables.tf#L32) | The GCS bucket configuration. | <code title="object&#40;&#123;&#10;  create                      &#61; optional&#40;bool, true&#41;&#10;  deletion_protection         &#61; optional&#40;bool, true&#41;&#10;  name                        &#61; optional&#40;string&#41;&#10;  uniform_bucket_level_access &#61; optional&#40;bool, true&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L44) | Context-specific interpolations. | <code title="object&#40;&#123;&#10;  custom_roles   &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  iam_principals &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  locations      &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  kms_keys       &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  project_ids    &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [description](variables.tf#L57) | The Agent Engine description. | <code>string</code> |  | <code>&#34;Terraform managed.&#34;</code> |
| [encryption_key](variables.tf#L64) | The full resource name of the Cloud KMS CryptoKey. | <code>string</code> |  | <code>null</code> |
| [generate_pickle](variables.tf#L70) | Generate the pickle file from a source file. | <code>bool</code> |  | <code>true</code> |
| [service_account_config](variables.tf#L95) | Service account configurations. | <code title="object&#40;&#123;&#10;  create &#61; optional&#40;bool, true&#41;&#10;  email  &#61; optional&#40;string&#41;&#10;  name   &#61; optional&#40;string&#41;&#10;  roles &#61; optional&#40;list&#40;string&#41;, &#91;&#10;    &#34;roles&#47;aiplatform.user&#34;,&#10;    &#34;roles&#47;storage.objectViewer&#34;,&#10;    &#34;roles&#47;viewer&#34;&#10;  &#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [source_files](variables.tf#L112) | The to source files path and names. | <code title="object&#40;&#123;&#10;  dependencies        &#61; optional&#40;string, &#34;dependencies.tar.gz&#34;&#41;&#10;  path                &#61; optional&#40;string, &#34;.&#47;src&#34;&#41;&#10;  pickle_out          &#61; optional&#40;string, &#34;pickle.pkl&#34;&#41;&#10;  pickle_src          &#61; optional&#40;string, &#34;agent.py&#34;&#41;&#10;  pickle_src_var_name &#61; optional&#40;string, &#34;local_agent&#34;&#41;&#10;  requirements        &#61; optional&#40;string, &#34;requirements.txt&#34;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [id](outputs.tf#L17) | Fully qualified Agent Engine id. |  |
| [service_account](outputs.tf#L22) | Service account resource. |  |
<!-- END TFDOC -->
