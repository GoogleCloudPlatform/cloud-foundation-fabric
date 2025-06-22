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

This module uses the API `discoveryengine.googleapis.com`

## Quota Project

To run this module you'll need to set a quota project.

```shell
export GOOGLE_BILLING_PROJECT=your-project-id
export USER_PROJECT_OVERRIDE=true
```

## Examples

### Chat Engine

This is a minimal example to create a Chat Engine agent.

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
    my-chat-engine = {
      data_store_ids = ["data-store-1"]
      chat_engine_config = {
        company_name          = "Google"
        default_language_code = "en"
        time_zone             = "America/Los_Angeles"
      }
    }
  }
}
# tftest modules=1 resources=2
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
    my-search-engine = {
      data_store_ids       = ["data-store-1"]
      search_engine_config = {}
    }
  }
}
# tftest modules=1 resources=2
```

### Deploy your service into a region

By default services are deployed globally. You optionally specify a region where to deploy them.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-chat-app"
  project_id = var.project_id
  location   = var.region
  data_stores_configs = {
    data-store-1 = {
      solution_types = ["SOLUTION_TYPE_CHAT"]
    }
  }
  engines_configs = {
    my-chat-engine = {
      data_store_ids = ["data-store-1"]
      chat_engine_config = {
        company_name          = "Google"
        default_language_code = "en"
        time_zone             = "America/Los_Angeles"
      }
    }
  }
}
# tftest modules=1 resources=2
```

### Reference existing data sources

You can reference from engines existing data sources created outside this module, by passing their ids. In this case, you'll need to configure in the engine valid `industry_vertical` and `location`.

```hcl
module "ai-applications" {
  source     = "./fabric/modules/ai-applications"
  name       = "my-search-app"
  project_id = var.project_id
  engines_configs = {
    my-search-engine = {
      data_store_ids = [
        "projects/my-project/locations/global/collections/my-collection/dataStores/data-store-1"
      ]
      industry_vertical    = "GENERIC"
      search_engine_config = {}
    }
  }
}
# tftest modules=1 resources=1
```

### Using multiple data stores

You can create and connect from your engines multiple data stores.

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
    my-chat-engine = {
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
}
# tftest modules=1 resources=3
```

### Set data store schemas

You can configure JSON data store schema definitions directly in your data store configuration.

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

You can make data stores point to multiple websites and optionally specify their sitemap.

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
    my-search-engine = {
      data_store_ids = [
        "website-search-ds"
      ]
      industry_vertical    = "GENERIC"
      search_engine_config = {}
    }
  }
}
# tftest modules=1 resources=5
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L159) | The name of the resources. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L165) | The ID of the project where the data stores and the agents will be created. | <code>string</code> | ✓ |  |
| [data_stores_configs](variables.tf#L17) | The ai-applications datastore configurations. | <code title="map&#40;object&#40;&#123;&#10;  advanced_site_search_config &#61; optional&#40;object&#40;&#123;&#10;    disable_initial_index     &#61; optional&#40;bool&#41;&#10;    disable_automatic_refresh &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  content_config              &#61; optional&#40;string, &#34;NO_CONTENT&#34;&#41;&#10;  create_advanced_site_search &#61; optional&#40;bool&#41;&#10;  display_name                &#61; optional&#40;string&#41;&#10;  document_processing_config &#61; optional&#40;object&#40;&#123;&#10;    chunking_config &#61; optional&#40;object&#40;&#123;&#10;      layout_based_chunking_config &#61; optional&#40;object&#40;&#123;&#10;        chunk_size                &#61; optional&#40;number&#41;&#10;        include_ancestor_headings &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    default_parsing_config &#61; optional&#40;object&#40;&#123;&#10;      digital_parsing_config &#61; optional&#40;bool&#41;&#10;      layout_parsing_config  &#61; optional&#40;bool&#41;&#10;      ocr_parsing_config &#61; optional&#40;object&#40;&#123;&#10;        use_native_text &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    parsing_config_overrides &#61; optional&#40;map&#40;object&#40;&#123;&#10;      digital_parsing_config &#61; optional&#40;bool&#41;&#10;      layout_parsing_config  &#61; optional&#40;bool&#41;&#10;      ocr_parsing_config &#61; optional&#40;object&#40;&#123;&#10;        use_native_text &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  industry_vertical            &#61; optional&#40;string, &#34;GENERIC&#34;&#41;&#10;  json_schema                  &#61; optional&#40;string&#41;&#10;  location                     &#61; optional&#40;string&#41;&#10;  skip_default_schema_creation &#61; optional&#40;bool&#41;&#10;  solution_types               &#61; optional&#40;list&#40;string&#41;&#41;&#10;  sites_search_config &#61; optional&#40;object&#40;&#123;&#10;    sitemap_uri &#61; optional&#40;string&#41;&#10;    target_sites &#61; map&#40;object&#40;&#123;&#10;      provided_uri_pattern &#61; string&#10;      exact_match          &#61; optional&#40;bool, false&#41;&#10;      type                 &#61; optional&#40;string, &#34;INCLUDE&#34;&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [engines_configs](variables.tf#L112) | The ai-applications engines configurations. | <code title="map&#40;object&#40;&#123;&#10;  data_store_ids &#61; list&#40;string&#41;&#10;  collection_id  &#61; optional&#40;string, &#34;default_collection&#34;&#41;&#10;  chat_engine_config &#61; optional&#40;object&#40;&#123;&#10;    allow_cross_region       &#61; optional&#40;bool, null&#41;&#10;    business                 &#61; optional&#40;string&#41;&#10;    company_name             &#61; optional&#40;string&#41;&#10;    default_language_code    &#61; optional&#40;string&#41;&#10;    dialogflow_agent_to_link &#61; optional&#40;string&#41;&#10;    time_zone                &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  industry_vertical &#61; optional&#40;string&#41;&#10;  location          &#61; optional&#40;string&#41;&#10;  search_engine_config &#61; optional&#40;object&#40;&#123;&#10;    search_add_ons &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    search_tier    &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L153) | Location where the data stores and agents will be created. | <code>string</code> |  | <code>&#34;global&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [chat_engine_ids](outputs.tf#L17) | The ids of the chat engines created. |  |
| [chat_engines](outputs.tf#L25) | The chat engines created. |  |
| [data_store_ids](outputs.tf#L30) | The ids of the data stores created. |  |
| [data_stores](outputs.tf#L38) | The data stores resources created. |  |
| [search_engine_ids](outputs.tf#L43) | The ids of the search engines created. |  |
| [search_engines](outputs.tf#L51) | The search engines created. |  |
<!-- END TFDOC -->
