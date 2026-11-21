/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "data_connectors" {
  description = "First-party and third-party SaaS data connectors in the location, keyed by logical connector ID and attached to apps via app_ids."
  type = map(object({
    data_source = string
    action_config = optional(object({
      action_params         = optional(map(string), {})
      create_bap_connection = optional(bool)
    }))
    app_ids           = optional(list(string), [])
    auto_run_disabled = optional(bool)
    bap_config = optional(object({
      enabled_actions           = optional(list(string), [])
      supported_connector_modes = optional(list(string))
    }))
    collection_display_name = optional(string)
    collection_id           = optional(string)
    connector_modes         = optional(list(string))
    data_source_version     = optional(number)
    destination_configs = optional(list(object({
      destinations = optional(list(object({
        host = optional(string)
        port = optional(number)
      })))
      key    = optional(string)
      params = optional(string)
    })), [])
    entities = optional(list(object({
      entity_name           = optional(string)
      key_property_mappings = optional(map(string))
      params                = optional(string)
    })), [])
    incremental_refresh_interval = optional(string)
    incremental_sync_disabled    = optional(bool)
    json_params                  = optional(string)
    kms_key                      = optional(string)
    metadata = optional(object({
      author            = optional(string)
      description       = optional(string)
      note              = optional(string)
      short_description = optional(string)
      title             = optional(string)
    }))
    params            = optional(map(string))
    refresh_interval  = optional(string, "86400s")
    static_ip_enabled = optional(bool, false)
    sync_mode         = optional(string)
    tag               = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue(flatten([
      for dc in var.data_connectors : [
        for m in coalesce(dc.connector_modes, []) :
        contains(
          ["DATA_INGESTION", "ACTIONS", "FEDERATED", "EUA", "FEDERATED_AND_EUA"],
          m
        )
      ]
    ]))
    error_message = "Each data_connectors[*].connector_modes value must be one of 'DATA_INGESTION', 'ACTIONS', 'FEDERATED', 'EUA', 'FEDERATED_AND_EUA'."
  }

  validation {
    condition = alltrue([
      for dc in var.data_connectors :
      dc.sync_mode == null || contains(["PERIODIC", "STREAMING"], dc.sync_mode)
    ])
    error_message = "data_connectors[*].sync_mode must be 'PERIODIC' or 'STREAMING'."
  }

  validation {
    condition = alltrue([
      for dc in var.data_connectors :
      !(dc.params != null && dc.json_params != null)
    ])
    error_message = "Only one of 'params' or 'json_params' may be set on a data connector."
  }
}

variable "data_stores" {
  description = "Native Discovery Engine data stores in the location, keyed by logical store ID and attached to apps via app_ids."
  type = map(object({
    acl_enabled    = optional(bool)
    app_ids        = optional(list(string), [])
    content_config = optional(string, "NO_CONTENT")
    data_store_id  = optional(string)
    display_name   = optional(string)
    document_processing_config = optional(object({
      chunking_config = optional(object({
        layout_based_chunking_config = optional(object({
          chunk_size                = optional(number)
          include_ancestor_headings = optional(bool)
        }))
      }))
      default_parsing_config = optional(object({
        digital_parsing_config = optional(bool)
        layout_parsing_config = optional(object({
          enable_get_processed_document = optional(bool)
          enable_image_annotation       = optional(bool)
          enable_llm_layout_parsing     = optional(bool)
          enable_table_annotation       = optional(bool)
          exclude_html_classes          = optional(list(string))
          exclude_html_elements         = optional(list(string))
          exclude_html_ids              = optional(list(string))
          structured_content_types      = optional(list(string))
        }))
        ocr_parsing_config = optional(object({
          use_native_text = optional(bool)
        }))
      }))
      parsing_config_overrides = optional(map(object({
        digital_parsing_config = optional(bool)
        layout_parsing_config = optional(object({
          enable_get_processed_document = optional(bool)
          enable_image_annotation       = optional(bool)
          enable_llm_layout_parsing     = optional(bool)
          enable_table_annotation       = optional(bool)
          exclude_html_classes          = optional(list(string))
          exclude_html_elements         = optional(list(string))
          exclude_html_ids              = optional(list(string))
          structured_content_types      = optional(list(string))
        }))
        ocr_parsing_config = optional(object({
          use_native_text = optional(bool)
        }))
      })))
    }))
    industry_vertical            = optional(string, "GENERIC")
    json_schema                  = optional(string)
    kms_key                      = optional(string)
    schema_id                    = optional(string, "default_schema")
    skip_default_schema_creation = optional(bool)
    solution_types               = optional(list(string), ["SOLUTION_TYPE_SEARCH"])
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for ds in var.data_stores : contains(
        ["CONTENT_REQUIRED", "NO_CONTENT"], ds.content_config
      )
    ])
    error_message = "data_stores[*].content_config must be 'CONTENT_REQUIRED' or 'NO_CONTENT'."
  }

  validation {
    condition = alltrue([
      for ds in var.data_stores : contains(
        ["GENERIC", "HEALTHCARE_FHIR", "MEDIA"], ds.industry_vertical
      )
    ])
    error_message = "data_stores[*].industry_vertical must be 'GENERIC', 'HEALTHCARE_FHIR', or 'MEDIA'."
  }

  validation {
    condition = alltrue(flatten([
      for ds in var.data_stores : [
        for st in coalesce(ds.solution_types, []) : contains(
          [
            "SOLUTION_TYPE_CHAT",
            "SOLUTION_TYPE_GENERATIVE_CHAT",
            "SOLUTION_TYPE_RECOMMENDATION",
            "SOLUTION_TYPE_SEARCH"
          ],
          st
        )
      ]
    ]))
    error_message = "data_stores[*].solution_types values must be valid Discovery Engine solution types."
  }

  validation {
    condition = alltrue(flatten([
      for ds in var.data_stores : [
        for k in keys(coalesce(
          try(ds.document_processing_config.parsing_config_overrides, null), {}
        )) :
        contains(["docx", "html", "pdf"], k)
      ]
    ]))
    error_message = "Keys in data_stores[*].document_processing_config.parsing_config_overrides must be 'docx', 'html', or 'pdf'."
  }
}

variable "mcp_connectors" {
  description = "Custom MCP server data connectors in the location, keyed by logical connector ID and attached to apps via app_ids."
  type = map(object({
    url           = string
    app_ids       = optional(list(string), [])
    collection_id = optional(string)
    display_name  = optional(string)
    oauth_config = optional(object({
      auth_uri                     = string
      client_id                    = string
      token_uri                    = string
      auth_uri_params              = optional(string)
      client_secret                = optional(string)
      client_secret_basic_override = optional(bool, true)
      pkce_support_enabled         = optional(bool, true)
      scopes                       = optional(list(string), [])
    }))
    refresh_interval         = optional(string, "86400s")
    use_agent_gateway_egress = optional(bool)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for mc in var.mcp_connectors : can(regex("^https?://.*", mc.url))
    ])
    error_message = "mcp_connectors[*].url must be a valid HTTP/HTTPS URL."
  }

  validation {
    condition = alltrue([
      for mc in var.mcp_connectors :
      mc.oauth_config == null
      ? true
      : can(regex("^https?://[^?#\\s]+$", mc.oauth_config.auth_uri))
    ])
    error_message = "mcp_connectors[*].oauth_config.auth_uri must be a valid HTTP/HTTPS URL without query parameters or fragments."
  }

  validation {
    condition = alltrue([
      for mc in var.mcp_connectors :
      try(mc.oauth_config.auth_uri_params, null) == null
      ? true
      : can(regex("^(&[^&=]+=[^&]+)*$", mc.oauth_config.auth_uri_params))
    ])
    error_message = "mcp_connectors[*].oauth_config.auth_uri_params must use query parameter format: &key1=value1&key2=value2."
  }

  validation {
    condition = alltrue([
      for mc in var.mcp_connectors :
      mc.oauth_config == null
      ? true
      : can(regex("^https?://.*", mc.oauth_config.token_uri))
    ])
    error_message = "mcp_connectors[*].oauth_config.token_uri must be a valid HTTP/HTTPS URL."
  }

  validation {
    condition = alltrue([
      for mc in var.mcp_connectors :
      mc.use_agent_gateway_egress != true || length(mc.app_ids) > 0
    ])
    error_message = "mcp_connectors with use_agent_gateway_egress = true must specify at least one target app in app_ids."
  }
}
