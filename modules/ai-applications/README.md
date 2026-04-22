# AI Applications

This module handles the creation of [AI Applications](https://cloud.google.com/generative-ai-app-builder/docs/introduction) data sources, engines and related configurations.

<!-- TOC -->
* [AI Applications module](#ai-applications)
  * [APIs](#apis)
  * [Quota Project](#quota-project)
  * [Examples](#examples)
    * [Chat Engine](#chat-engine)
    * [Search Engine](#search-engine)
    * [Deploy your service into a region](#deploy-your-service-into-a-region)
    * [Reference Existing Data Sources](#reference-existing-data-sources)
    * [Using multiple data stores](#using-multiple-data-stores)
    * [Set data store schemas](#set-data-store-schemas)
    * [Back data stores with websites data](#back-data-stores-with-websites-data)
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
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L483) | The name of the resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L489) | The ID of the project where the data stores and the agents will be created. | <code>string</code> | ✓ |  |
| [chat_agent_security_configs](variables.tf#L17) | The DLP security configurations for (Dialogflow CX) chat agents. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_stores_configs](variables.tf#L305) | The ai-applications datastore configurations. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [engines_configs](variables.tf#L410) | The AI applications engines configurations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L477) | Location where the data stores and agents will be created. | <code>string</code> |  | <code>&#34;global&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [chat_agent](outputs.tf#L17) | The (Dialogflow CX) chat agent object. |  |
| [chat_agent_id](outputs.tf#L22) | The id of the (Dialogflow CX) chat agent. |  |
| [chat_engine](outputs.tf#L27) | The chat engine object. |  |
| [chat_engine_id](outputs.tf#L32) | The id of the chat engine. |  |
| [data_store_ids](outputs.tf#L37) | The ids of the data stores created. |  |
| [data_stores](outputs.tf#L45) | The data stores resources created. |  |
| [search_engine](outputs.tf#L50) | The search engines object. |  |
| [search_engine_id](outputs.tf#L55) | The id of the search engine. |  |
<!-- END TFDOC -->
