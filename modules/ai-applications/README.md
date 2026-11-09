# AI Applications

This module handles the creation of [AI Applications](https://cloud.google.com/generative-ai-app-builder/docs/introduction) data sources, engines and related configurations.

<!-- TOC -->
* [AI Applications module](#ai-applications)
  * [APIs](#apis)
  * [Quota Project](#quota-project)
  * [Examples](#examples)
    * [Chat Engine](#chat-engine)
    * [Search Engine](#search-engine)
    * [Gemini Enterprise](#gemini-enterprise)
    * [Deploy your service into a region](#deploy-your-service-into-a-region)
    * [Reference Existing Data Sources](#reference-existing-data-sources)
    * [Using multiple data stores](#using-multiple-data-stores)
    * [Set data store schemas](#set-data-store-schemas)
    * [Back data stores with websites data](#back-data-stores-with-websites-data)
    * [CMEK](#cmek)
  * [Variables](#variables)
  * [Outputs](#outputs)
<!-- TOC -->

## APIs

This module uses these APIs

- `discoveryengine.googleapis.com`
- `dialogflow.googleapis.com` (if you create a chat engine)

## Quota Project

To run this module you'll need to set a quota project.

```shell
export GOOGLE_BILLING_PROJECT=your-project-id
export USER_PROJECT_OVERRIDE=true
```

## Examples

### Chat Engine

This is a minimal example to create a Chat Engine (Dialogflow CX) agent.
By default, this uses the location `global` for engines, agents and data stores.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-chat-app"
  project_id = var.project_id
  data_stores_configs = {
    data-store-1 = {
      solution_types = ["SOLUTION_TYPE_CHAT"]
    }
  }
  engines_configs = {
    data_store_ids = ["data-store-1"]
    chat_engine_config = {
      company_name          = "Google"
      default_language_code = "en"
      time_zone             = "America/Los_Angeles"
    }
  }
}
# tftest modules=1 resources=3
```

You can change this location for all components.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-chat-app"
  project_id = var.project_id
  location   = "eu"
  data_stores_configs = {
    data-store-1 = {
      solution_types = ["SOLUTION_TYPE_CHAT"]
    }
  }
  engines_configs = {
    data_store_ids = ["data-store-1"]
    chat_engine_config = {
      company_name          = "Google"
      default_language_code = "en"
      time_zone             = "America/Los_Angeles"
    }
  }
}
# tftest modules=1 resources=3
```

You may need to create the Dialogflow CX agent in a specific region.
While the agent can be created within a specific region, the engine and the data stores still need to be created in multi-regional locations. Refer to [this table](https://docs.cloud.google.com/dialogflow/cx/docs/concept/region#avail) for the compatibility matrix.
In this case, you need to specify different locations for each component.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-chat-app"
  project_id = var.project_id
  data_stores_configs = {
    data-store-1 = {
      solution_types = ["SOLUTION_TYPE_CHAT"]
    }
  }
  engines_configs = {
    data_store_ids = ["data-store-1"]
    location       = "eu"
    chat_engine_config = {
      company_name          = "Google"
      default_language_code = "en"
      time_zone             = "America/Los_Angeles"
      agent_config = {
        location = "europe-west1"
      }
    }
  }
}
# tftest modules=1 resources=3
```

Instead of creating a new agent, you can reference an existing agent.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-chat-app"
  project_id = var.project_id
  data_stores_configs = {
    data-store-1 = {
      solution_types = ["SOLUTION_TYPE_CHAT"]
    }
  }
  engines_configs = {
    data_store_ids = ["data-store-1"]
    chat_engine_config = {
      company_name          = "Google"
      default_language_code = "en"
      time_zone             = "America/Los_Angeles"
      agent_config = {
        security_settings_config = {
          id = "projects/my-project/locations/global/agents/my-agent"
        }
      }
    }
  }
}
# tftest modules=1 resources=3
```

If you create and agent, you can also create the agent security settings.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-chat-app"
  project_id = var.project_id
  data_stores_configs = {
    data-store-1 = {
      solution_types = ["SOLUTION_TYPE_CHAT"]
    }
  }
  engines_configs = {
    data_store_ids = ["data-store-1"]
    chat_engine_config = {
      company_name          = "Google"
      default_language_code = "en"
      time_zone             = "America/Los_Angeles"
      agent_config = {
        security_settings_config = {
          create = true
        }
      }
    }
  }
}
# tftest modules=1 resources=4
```

With the `security_settings_config` you can control every security aspect of the agent, including the creation of the DLP inspect and deidentify templates.

You can also reference an existing security profile by passing its id.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-chat-app"
  project_id = var.project_id
  data_stores_configs = {
    data-store-1 = {
      solution_types = ["SOLUTION_TYPE_CHAT"]
    }
  }
  engines_configs = {
    data_store_ids = ["data-store-1"]
    chat_engine_config = {
      company_name          = "Google"
      default_language_code = "en"
      time_zone             = "America/Los_Angeles"
      agent_config = {
        security_settings_config = {
          create = false
          id     = "projects/my-project/locations/global/securitySettings/my-sec-settings"
        }
      }
    }
  }
}
# tftest modules=1 resources=3
```

### Search Engine

This is a minimal example to create a Search Engine agent.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-search-app"
  project_id = var.project_id
  data_stores_configs = {
    data-store-1 = {
      solution_types = ["SOLUTION_TYPE_SEARCH"]
    }
  }
  engines_configs = {
    data_store_ids       = ["data-store-1"]
    search_engine_config = {}
  }
}
# tftest modules=1 resources=2
```

### Gemini Enterprise

This example provisions a regional Gemini Enterprise (`APP_TYPE_INTRANET`) application with identity ACL configuration, automatic license seat registration via `default_user_store`, a Cloud Storage knowledge connector (`auto_generate_ids = false` for unstructured documents), a web app widget, and resource-level `roles/discoveryengine.agentspaceUser` IAM bindings.

```hcl
module "gemini-enterprise" {
  source     = "./fabric/modules/ai-applications"
  name       = "gemini-enterprise-prod"
  project_id = var.project_id
  location   = "us"
  acl_config = {
    idp_type = "GSUITE"
  }
  license_config = {
    create_free_trial            = true
    enable_license_auto_register = true
  }
  data_stores_configs = {
    knowledge-store = {
      content_config              = "CONTENT_REQUIRED"
      create_advanced_site_search = false
      display_name                = "Enterprise Knowledge Store"
      solution_types              = ["SOLUTION_TYPE_SEARCH"]
      document_processing_config = {
        chunking_config = {
          layout_based_chunking_config = {
            chunk_size                = 500
            include_ancestor_headings = true
          }
        }
        default_parsing_config = {
          digital_parsing_config = true
        }
      }
    }
    reserved-store = {
      content_config              = "NO_CONTENT"
      create_advanced_site_search = false
      display_name                = "Reserved Secondary Store"
      solution_types              = ["SOLUTION_TYPE_SEARCH"]
    }
  }
  data_connectors_configs = {
    gcs-corpus = {
      collection_display_name = "Cloud Storage Knowledge Connector"
      connector_modes         = ["DATA_INGESTION"]
      data_source             = "gcs"
      json_params = jsonencode({
        instance_uris = ["gs://my-enterprise-corpus/docs/*"]
      })
      entities = [
        {
          entity_name = "gcs_store"
          params = jsonencode({
            data_schema       = "content"
            auto_generate_ids = false
          })
        }
      ]
    }
    google-drive = {
      collection_display_name = "Google Drive"
      connector_modes         = ["FEDERATED"]
      data_source             = "google_drive"
      refresh_interval        = "0s"
      auto_run_disabled       = true
      entities = [
        { entity_name = "google_drive" }
      ]
    }
    google-mail = {
      collection_display_name = "Gmail"
      connector_modes         = ["FEDERATED"]
      data_source             = "google_mail"
      refresh_interval        = "0s"
      auto_run_disabled       = true
      entities = [
        { entity_name = "google_mail" }
      ]
    }
    google-calendar = {
      collection_display_name = "Google Calendar"
      connector_modes         = ["FEDERATED"]
      data_source             = "google_calendar"
      refresh_interval        = "0s"
      auto_run_disabled       = true
      entities = [
        { entity_name = "google_calendar" }
      ]
    }
    google-chat = {
      collection_display_name = "Google Chat"
      connector_modes         = ["FEDERATED", "ACTIONS"]
      data_source             = "google_chat"
      refresh_interval        = "0s"
      auto_run_disabled       = true
      action_config = {
        create_bap_connection = true
        action_params = {
          auth_type = "OAUTH"
          auth_key  = "OAuth"
        }
      }
      entities = [
        { entity_name = "google_chat" }
      ]
    }
  }
  engines_configs = {
    data_store_ids = ["knowledge-store", "reserved-store"]
    search_engine_config = {
      app_type                       = "APP_TYPE_INTRANET"
      company_name                   = "Example Enterprise"
      display_name                   = "Gemini Enterprise (Production)"
      enable_private_knowledge_graph = true
      search_add_ons                 = ["SEARCH_ADD_ON_LLM"]
      search_tier                    = "SEARCH_TIER_ENTERPRISE"
      features = {
        "agent-sharing-without-admin-approval" = "FEATURE_STATE_OFF"
        "disable-agent-sharing"                = "FEATURE_STATE_OFF"
        "enable-end-user-sharing-with-groups"  = "FEATURE_STATE_OFF"
        "model-selector"                       = "FEATURE_STATE_ON"
        "no-code-agent-builder"                = "FEATURE_STATE_ON"
        "notebook-lm"                          = "FEATURE_STATE_ON"
        "personalization-suggested-highlights" = "FEATURE_STATE_ON"
        "prompt-gallery"                       = "FEATURE_STATE_ON"
        "workflow-agents"                      = "FEATURE_STATE_ON"
      }
      iam = {
        "roles/discoveryengine.agentspaceUser" = ["domain:example.com"]
      }
      widget_config = {
        enable_web_app = true
      }
    }
  }
}
# tftest modules=1 resources=13
```

### Data stores

You can create and connect from your engines multiple data stores.
Data stores can be either created in the module or you can reference existing data stores, by passing their id.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-chat-app"
  project_id = var.project_id
  data_stores_configs = {
    data-store-1 = {
      solution_types = ["SOLUTION_TYPE_CHAT"]
    }
    data-store-2 = {
      solution_types = ["SOLUTION_TYPE_CHAT"]
    }
  }
  engines_configs = {
    data_store_ids = [
      "data-store-1",
      "data-store-2",
      "projects/my-project/locations/global/collections/default_collection/dataStores/data-store-3"
    ]
    chat_engine_config = {
      company_name          = "Google"
      default_language_code = "en"
      time_zone             = "America/Los_Angeles"
    }
  }
}
# tftest modules=1 resources=4
```

### Set data store schemas

You can configure JSON data store schemas directly in your data store configuration.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-search-app"
  project_id = var.project_id
  data_stores_configs = {
    data-store-1 = {
      json_schema    = "{\"$schema\":\"https://json-schema.org/draft/2020-12/schema\",\"datetime_detection\":true,\"type\":\"object\",\"geolocation_detection\":true}"
      solution_types = ["SOLUTION_TYPE_SEARCH"]
    }
  }
}
# tftest modules=1 resources=2
```

### Back data stores with websites data

For search engines, you can make data stores point to multiple websites and optionally specify their sitemap.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-search-app"
  project_id = var.project_id
  data_stores_configs = {
    website-search-ds = {
      solution_types = ["SOLUTION_TYPE_SEARCH"]
      sites_search_config = {
        sitemap_uri = "https://cloud.google.com/sitemap.xml"
        target_sites = {
          include-google-docs = {
            provided_uri_pattern = "cloud.google.com/docs/*"
          }
          exclude-one-page = {
            exact_match          = true
            provided_uri_pattern = "https://cloud.google.com/ai-applications"
            type                 = "EXCLUDE"
          }
        }
      }
    }
  }
  engines_configs = {
    data_store_ids = [
      "website-search-ds"
    ]
    industry_vertical    = "GENERIC"
    search_engine_config = {}
  }
}
# tftest modules=1 resources=5
```

### CMEK

Use `encryption_configs` to register Customer-Managed Encryption Keys for the project, one per multi-region location (`us`, `eu`). The module creates data stores and engines only after keys are registered, as resources created before registration stay encrypted with Google-managed keys. With `set_default` (the default), new data stores in that location use the registered key. Use `kms_key` in a data store configuration to set its key explicitly.

KMS keys, locations and the project id can also be passed via `context` and referenced symbolically, as shown here.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-search-app"
  project_id = "$project_ids:app"
  location   = "$locations:primary"
  context = {
    kms_keys = {
      eu = "projects/my-kms-project/locations/eu/keyRings/my-keyring/cryptoKeys/my-key"
      us = "projects/my-kms-project/locations/us/keyRings/my-keyring/cryptoKeys/my-key"
    }
    locations = {
      primary = "eu"
    }
    project_ids = {
      app = var.project_id
    }
  }
  encryption_configs = {
    eu = {
      kms_key = "$kms_keys:eu"
    }
    us = {
      kms_key = "$kms_keys:us"
    }
  }
  data_stores_configs = {
    data-store-1 = {
      kms_key        = "$kms_keys:eu"
      solution_types = ["SOLUTION_TYPE_SEARCH"]
    }
  }
  engines_configs = {
    data_store_ids       = ["data-store-1"]
    search_engine_config = {}
  }
}
# tftest modules=1 resources=4 inventory=cmek.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L608) | The name of the resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L614) | The ID of the project where the data stores and the agents will be created. | <code>string</code> | ✓ |  |
| [acl_config](variables.tf#L17) | Regional identity ACL configuration for Gemini Enterprise (GSUITE or THIRD_PARTY Workforce Identity Federation). | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [chat_agent_security_configs](variables.tf#L41) | The DLP security configurations for (Dialogflow CX) chat agents. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L329) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_connectors_configs](variables.tf#L341) | Discovery Engine data connector configurations (1P/3P ingestion, federated search, and actions). | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_stores_configs](variables.tf#L382) | The ai-applications datastore configurations. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [encryption_configs](variables.tf#L488) | CMEK configurations registered for the project, keyed by location (e.g. us, eu). Data stores and engines are created after keys are registered. KMS key format: 'projects/[PROJECT]/locations/[LOCATION]/keyRings/[RING]/cryptoKeys/[KEY_NAME]'. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [engines_configs](variables.tf#L499) | The AI applications engines configurations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [license_config](variables.tf#L587) | Gemini Enterprise license configuration and automatic seat assignment via default_user_store. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [location](variables.tf#L602) | Location where the data stores and agents will be created. | <code>string</code> |  | <code>&#34;global&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [chat_agent](outputs.tf#L17) | The (Dialogflow CX) chat agent object. |  |
| [chat_agent_id](outputs.tf#L22) | The id of the (Dialogflow CX) chat agent. |  |
| [chat_engine](outputs.tf#L27) | The chat engine object. |  |
| [chat_engine_id](outputs.tf#L32) | The id of the chat engine. |  |
| [data_connectors](outputs.tf#L37) | The Discovery Engine data connectors created. |  |
| [data_store_ids](outputs.tf#L42) | The ids of the data stores created. |  |
| [data_stores](outputs.tf#L50) | The data stores resources created. |  |
| [search_engine](outputs.tf#L55) | The search engines object. |  |
| [search_engine_id](outputs.tf#L60) | The id of the search engine. |  |
| [user_store](outputs.tf#L65) | The Discovery Engine default user store object. |  |
| [widget_config](outputs.tf#L70) | The Discovery Engine widget configuration object. |  |
<!-- END TFDOC -->
