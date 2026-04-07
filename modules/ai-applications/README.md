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
| [chat_agent_security_configs](variables.tf#L17) | The DLP security configurations for (Dialogflow CX) chat agents. | <code title="object&#40;&#123;&#10;  audio_export_settings &#61; optional&#40;object&#40;&#123;&#10;    audio_format &#61; string&#10;    gcs_bucket_config &#61; object&#40;&#123;&#10;      id         &#61; optional&#40;string&#41;&#10;      prefix     &#61; string&#10;      location   &#61; optional&#40;string&#41;&#10;      name       &#61; optional&#40;string&#41;&#10;      versioning &#61; optional&#40;bool, true&#41;&#10;    &#125;&#41;&#10;    audio_export_pattern   &#61; string&#10;    enable_audio_redaction &#61; optional&#40;bool, false&#41;&#10;  &#125;&#41;&#41;&#10;  dlp_deidentify_template &#61; optional&#40;object&#40;&#123;&#10;    description  &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;    display_name &#61; optional&#40;string&#41;&#10;    info_type_transformations &#61; optional&#40;object&#40;&#123;&#10;      transformations &#61; list&#40;object&#40;&#123;&#10;        info_types &#61; optional&#40;list&#40;object&#40;&#123;&#10;          name              &#61; string&#10;          version           &#61; optional&#40;string&#41;&#10;          sensitivity_score &#61; optional&#40;string&#41;&#10;        &#125;&#41;&#41;&#41;&#10;        primitive_transformation &#61; any&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    parent &#61; optional&#40;string&#41;&#10;    record_transformations &#61; optional&#40;object&#40;&#123;&#10;      field_transformations &#61; optional&#40;list&#40;object&#40;&#123;&#10;        fields &#61; list&#40;object&#40;&#123; name &#61; string &#125;&#41;&#41;&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          expressions &#61; optional&#40;object&#40;&#123;&#10;            logical_operator &#61; optional&#40;string&#41;&#10;            conditions &#61; list&#40;object&#40;&#123;&#10;              field    &#61; object&#40;&#123; name &#61; string &#125;&#41;&#10;              operator &#61; string&#10;              value &#61; optional&#40;object&#40;&#123;&#10;                integer_value   &#61; optional&#40;number&#41;&#10;                float_value     &#61; optional&#40;number&#41;&#10;                string_value    &#61; optional&#40;string&#41;&#10;                boolean_value   &#61; optional&#40;bool&#41;&#10;                timestamp_value &#61; optional&#40;string&#41;&#10;              &#125;&#41;&#41;&#10;            &#125;&#41;&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        primitive_transformation &#61; optional&#40;object&#40;&#123;&#10;          replace_config &#61; optional&#40;object&#40;&#123;&#10;            new_value &#61; object&#40;&#123;&#10;              integer_value   &#61; optional&#40;number&#41;&#10;              float_value     &#61; optional&#40;number&#41;&#10;              string_value    &#61; optional&#40;string&#41;&#10;              boolean_value   &#61; optional&#40;bool&#41;&#10;              timestamp_value &#61; optional&#40;string&#41;&#10;              time_value &#61; optional&#40;object&#40;&#123;&#10;                hours   &#61; optional&#40;number&#41;&#10;                minutes &#61; optional&#40;number&#41;&#10;                seconds &#61; optional&#40;number&#41;&#10;                nanos   &#61; optional&#40;number&#41;&#10;              &#125;&#41;&#41;&#10;              date_value &#61; optional&#40;object&#40;&#123;&#10;                year  &#61; optional&#40;number&#41;&#10;                month &#61; optional&#40;number&#41;&#10;                day   &#61; optional&#40;number&#41;&#10;              &#125;&#41;&#41;&#10;              day_of_week_value &#61; optional&#40;string&#41;&#10;            &#125;&#41;&#10;          &#125;&#41;&#41;&#10;          character_mask_config &#61; optional&#40;object&#40;&#123;&#10;            masking_character &#61; optional&#40;string&#41;&#10;            number_to_mask    &#61; optional&#40;number&#41;&#10;            reverse_order     &#61; optional&#40;bool&#41;&#10;            characters_to_ignore &#61; optional&#40;object&#40;&#123;&#10;              characters_to_skip          &#61; optional&#40;string&#41;&#10;              common_characters_to_ignore &#61; optional&#40;string&#41;&#10;            &#125;&#41;&#41;&#10;          &#125;&#41;&#41;&#10;          crypto_replace_ffx_fpe_config &#61; optional&#40;object&#40;&#123;&#10;            crypto_key &#61; optional&#40;object&#40;&#123;&#10;              transient   &#61; optional&#40;object&#40;&#123; name &#61; string &#125;&#41;&#41;&#10;              unwrapped   &#61; optional&#40;object&#40;&#123; key &#61; string &#125;&#41;&#41;&#10;              kms_wrapped &#61; optional&#40;object&#40;&#123; wrapped_key &#61; string, crypto_key_name &#61; string &#125;&#41;&#41;&#10;            &#125;&#41;&#41;&#10;            context &#61; optional&#40;object&#40;&#123; name &#61; optional&#40;string&#41; &#125;&#41;&#41;&#10;            surrogate_info_type &#61; optional&#40;object&#40;&#123;&#10;              name              &#61; optional&#40;string&#41;&#10;              version           &#61; optional&#40;string&#41;&#10;              sensitivity_score &#61; optional&#40;string&#41;&#10;            &#125;&#41;&#41;&#10;            common_alphabet &#61; optional&#40;string&#41;&#10;            custom_alphabet &#61; optional&#40;string&#41;&#10;            radix           &#61; optional&#40;number&#41;&#10;          &#125;&#41;&#41;&#10;          crypto_deterministic_config &#61; optional&#40;any&#41;&#10;          replace_dictionary_config   &#61; optional&#40;any&#41;&#10;          date_shift_config           &#61; optional&#40;any&#41;&#10;          fixed_size_bucketing_config &#61; optional&#40;any&#41;&#10;          bucketing_config            &#61; optional&#40;any&#41;&#10;          time_part_config            &#61; optional&#40;any&#41;&#10;          redact_config               &#61; optional&#40;bool&#41;&#10;          crypto_hash_config          &#61; optional&#40;any&#41;&#10;        &#125;&#41;&#41;&#10;        info_type_transformations &#61; optional&#40;object&#40;&#123;&#10;          transformations &#61; list&#40;object&#40;&#123;&#10;            info_types &#61; optional&#40;list&#40;object&#40;&#123;&#10;              name              &#61; string&#10;              version           &#61; optional&#40;string&#41;&#10;              sensitivity_score &#61; optional&#40;string&#41;&#10;            &#125;&#41;&#41;&#41;&#10;            primitive_transformation &#61; optional&#40;any&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;&#41;&#10;      record_suppressions &#61; optional&#40;list&#40;object&#40;&#123;&#10;        condition &#61; optional&#40;object&#40;&#123;&#10;          expressions &#61; optional&#40;object&#40;&#123;&#10;            logical_operator &#61; optional&#40;string&#41;&#10;            conditions &#61; list&#40;object&#40;&#123;&#10;              field    &#61; object&#40;&#123; name &#61; string &#125;&#41;&#10;              operator &#61; string&#10;              value &#61; optional&#40;object&#40;&#123;&#10;                integer_value   &#61; optional&#40;number&#41;&#10;                float_value     &#61; optional&#40;number&#41;&#10;                string_value    &#61; optional&#40;string&#41;&#10;                boolean_value   &#61; optional&#40;bool&#41;&#10;                timestamp_value &#61; optional&#40;string&#41;&#10;              &#125;&#41;&#41;&#10;            &#125;&#41;&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    template_id &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  dlp_inspect_template &#61; optional&#40;object&#40;&#123;&#10;    content_options &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    custom_info_types &#61; optional&#40;map&#40;object&#40;&#123;&#10;      dictionary &#61; optional&#40;object&#40;&#123;&#10;        cloud_storage_path &#61; optional&#40;string&#41;&#10;        words_list         &#61; optional&#40;list&#40;string&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      exclusion_type &#61; optional&#40;string&#41;&#10;      likelihood &#61; optional&#40;string, &#34;VERY_LIKELY&#34;&#41;&#10;      regex &#61; optional&#40;object&#40;&#123;&#10;        pattern       &#61; string&#10;        group_indexes &#61; optional&#40;list&#40;number&#41;&#41;&#10;      &#125;&#41;&#41;&#10;      sensitivity_score &#61; optional&#40;string&#41;&#10;      stored_type_name  &#61; optional&#40;string&#41;&#10;      surrogate_type    &#61; optional&#40;string&#41;&#10;      version           &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;&#41;&#10;    description        &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;    exclude_info_types &#61; optional&#40;bool, false&#41;&#10;    include_quote      &#61; optional&#40;bool, false&#41;&#10;    info_types &#61; optional&#40;map&#40;object&#40;&#123;&#10;      sensitivity_score &#61; optional&#40;string, &#34;SENSITIVITY_MODERATE&#34;&#41;&#10;      version           &#61; optional&#40;string&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    limits &#61; optional&#40;object&#40;&#123;&#10;      max_findings_per_item    &#61; optional&#40;number, 2000&#41;&#10;      max_findings_per_request &#61; optional&#40;number, 2000&#41;&#10;      max_findings_per_info_type &#61; optional&#40;map&#40;object&#40;&#123;&#10;        max_findings &#61; optional&#40;number, 2000&#41;&#10;        sensitivity_score &#61; optional&#40;string, &#34;SENSITIVITY_MODERATE&#34;&#41;&#10;        version           &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    min_likelihood &#61; optional&#40;string, &#34;POSSIBLE&#34;&#41;&#10;    name           &#61; optional&#40;string&#41;&#10;    parent         &#61; optional&#40;string&#41;&#10;    rule_sets &#61; optional&#40;map&#40;object&#40;&#123;&#10;      info_types &#61; map&#40;object&#40;&#123;&#10;        version &#61; optional&#40;string&#41;&#10;        sensitivity_score &#61; optional&#40;string, &#34;SENSITIVITY_MODERATE&#34;&#41;&#10;      &#125;&#41;&#41;&#10;      rules &#61; object&#40;&#123;&#10;        exclusion_rule &#61; optional&#40;object&#40;&#123;&#10;          matching_type &#61; string&#10;          dictionary &#61; optional&#40;object&#40;&#123;&#10;            cloud_storage_path &#61; optional&#40;string&#41;&#10;            words_list         &#61; optional&#40;list&#40;string&#41;&#41;&#10;          &#125;&#41;&#41;&#10;          regex &#61; optional&#40;object&#40;&#123;&#10;            pattern       &#61; string&#10;            group_indexes &#61; optional&#40;list&#40;number&#41;&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;        hotword_rule &#61; optional&#40;object&#40;&#123;&#10;          hotword_regex &#61; object&#40;&#123;&#10;            pattern       &#61; string&#10;            group_indexes &#61; optional&#40;list&#40;number&#41;&#41;&#10;          &#125;&#41;&#10;          proximity &#61; object&#40;&#123;&#10;            window_after  &#61; optional&#40;number&#41;&#10;            window_before &#61; optional&#40;number&#41;&#10;          &#125;&#41;&#10;          likelihood_adjustment &#61; optional&#40;object&#40;&#123;&#10;            fixed_likelihood    &#61; optional&#40;string&#41;&#10;            relative_likelihood &#61; optional&#40;number&#41;&#10;          &#125;&#41;&#41;&#10;        &#125;&#41;&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;, &#123;&#125;&#41;&#10;    template_id &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  enable_insights_export &#61; optional&#40;bool, false&#41;&#10;  location               &#61; optional&#40;string&#41;&#10;  purge_data_types       &#61; optional&#40;list&#40;string&#41;&#41;&#10;  redaction_scope        &#61; optional&#40;string&#41;&#10;  redaction_strategy     &#61; optional&#40;string&#41;&#10;  retention_window_days  &#61; optional&#40;number&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_stores_configs](variables.tf#L305) | The ai-applications datastore configurations. | <code title="map&#40;object&#40;&#123;&#10;  advanced_site_search_config &#61; optional&#40;object&#40;&#123;&#10;    disable_initial_index     &#61; optional&#40;bool&#41;&#10;    disable_automatic_refresh &#61; optional&#40;bool&#41;&#10;  &#125;&#41;&#41;&#10;  content_config              &#61; optional&#40;string, &#34;NO_CONTENT&#34;&#41;&#10;  create_advanced_site_search &#61; optional&#40;bool&#41;&#10;  display_name                &#61; optional&#40;string&#41;&#10;  document_processing_config &#61; optional&#40;object&#40;&#123;&#10;    chunking_config &#61; optional&#40;object&#40;&#123;&#10;      layout_based_chunking_config &#61; optional&#40;object&#40;&#123;&#10;        chunk_size                &#61; optional&#40;number&#41;&#10;        include_ancestor_headings &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    default_parsing_config &#61; optional&#40;object&#40;&#123;&#10;      digital_parsing_config &#61; optional&#40;bool&#41;&#10;      layout_parsing_config  &#61; optional&#40;bool&#41;&#10;      ocr_parsing_config &#61; optional&#40;object&#40;&#123;&#10;        use_native_text &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#10;    parsing_config_overrides &#61; optional&#40;map&#40;object&#40;&#123;&#10;      digital_parsing_config &#61; optional&#40;bool&#41;&#10;      layout_parsing_config  &#61; optional&#40;bool&#41;&#10;      ocr_parsing_config &#61; optional&#40;object&#40;&#123;&#10;        use_native_text &#61; optional&#40;bool&#41;&#10;      &#125;&#41;&#41;&#10;    &#125;&#41;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  industry_vertical            &#61; optional&#40;string, &#34;GENERIC&#34;&#41;&#10;  json_schema                  &#61; optional&#40;string&#41;&#10;  location                     &#61; optional&#40;string&#41;&#10;  skip_default_schema_creation &#61; optional&#40;bool&#41;&#10;  solution_types               &#61; optional&#40;list&#40;string&#41;&#41;&#10;  sites_search_config &#61; optional&#40;object&#40;&#123;&#10;    sitemap_uri &#61; optional&#40;string&#41;&#10;    target_sites &#61; map&#40;object&#40;&#123;&#10;      provided_uri_pattern &#61; string&#10;      exact_match          &#61; optional&#40;bool, false&#41;&#10;      type                 &#61; optional&#40;string, &#34;INCLUDE&#34;&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [engines_configs](variables.tf#L410) | The AI applications engines configurations. | <code title="object&#40;&#123;&#10;  chat_engine_config &#61; optional&#40;object&#40;&#123;&#10;    agent_config &#61; optional&#40;object&#40;&#123;&#10;      avatar_uri            &#61; optional&#40;string&#41;&#10;      default_language_code &#61; optional&#40;string&#41;&#10;      description           &#61; optional&#40;string, &#34;Terraform managed.&#34;&#41;&#10;      id &#61; optional&#40;string&#41;&#10;      location &#61; optional&#40;string&#41;&#10;      security_settings_config &#61; optional&#40;object&#40;&#123;&#10;        create &#61; optional&#40;bool, false&#41;&#10;        id     &#61; optional&#40;string&#41;&#10;      &#125;&#41;&#41;&#10;      supported_language_codes &#61; optional&#40;list&#40;string&#41;&#41;&#10;      time_zone                &#61; optional&#40;string&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    allow_cross_region &#61; optional&#40;bool, true&#41;&#10;    business           &#61; optional&#40;string&#41;&#10;    company_name       &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;  collection_id  &#61; optional&#40;string, &#34;default_collection&#34;&#41;&#10;  data_store_ids &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  industry_vertical &#61; optional&#40;string&#41;&#10;  location &#61; optional&#40;string&#41;&#10;  search_engine_config &#61; optional&#40;object&#40;&#123;&#10;    search_add_ons &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;    search_tier    &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [location](variables.tf#L477) | Location where the data stores and agents will be created. | <code>string</code> |  | <code>&#34;global&#34;</code> |

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
