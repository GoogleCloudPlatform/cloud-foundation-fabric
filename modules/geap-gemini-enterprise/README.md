# GEAP Gemini Enterprise

This module manages a Gemini Enterprise tenant in a single Discovery Engine multi-region location (`global`, `us`, or `eu`) within a project, including location-level identity (`acl_config`), seat licensing (`default_user_store`), CMEK (`cmek_config`), shared native data stores, first-party/third-party SaaS and Custom MCP data connectors, and one or more intranet applications (`APP_TYPE_INTRANET`) with assistants, search widgets, Egress Agent Gateway bindings, and app-level IAM.

<!-- BEGIN TOC -->
- [API and prerequisites](#api-and-prerequisites)
  - [Project-level companion IAM](#project-level-companion-iam)
- [Minimal tenant and intranet app](#minimal-tenant-and-intranet-app)
- [Native data stores and CMEK](#native-data-stores-and-cmek)
- [SaaS and Custom MCP connectors with Egress Agent Gateway](#saas-and-custom-mcp-connectors-with-egress-agent-gateway)
- [Adopting an existing app and managing the default assistant](#adopting-an-existing-app-and-managing-the-default-assistant)
- [Context](#context)
- [Variables](#variables)
- [Outputs](#outputs)
<!-- END TOC -->

## API and prerequisites

Enable the `discoveryengine.googleapis.com` API in the target project before deploying this module (plus `cloudkms.googleapis.com` when registering CMEK keys, `modelarmor.googleapis.com` when referencing Model Armor templates, and `networkservices.googleapis.com` when binding an Egress Agent Gateway).

When authenticating with local user Application Default Credentials (ADC), configure `user_project_override = true` and `billing_project` on the `google` provider because `discoveryengine.googleapis.com` requires a quota project. When referencing Secret Manager secret versions in `oauth_config` (`client_id` / `client_secret`), grant `roles/secretmanager.secretAccessor` on those secrets to the Discovery Engine service agent (`service-<PROJECT_NUMBER>@gcp-sa-discoveryengine.iam.gserviceaccount.com`).

When attaching data stores or connectors to engines or binding an Egress Agent Gateway, apply and destroy steps invoke authenticated Discovery Engine REST `PATCH` calls and require `curl`, `gcloud`, and `jq` in `PATH`.

### Project-level companion IAM

This module scopes IAM management strictly to Gemini Enterprise engines (`google_discovery_engine_search_engine_iam_*`). Users granted roles on an app (such as `roles/discoveryengine.agentspaceUser`) also require `roles/discoveryengine.agentspaceRestrictedUser` on the project to reach apps and connectors. Pass the deduplicated `app_iam_principals` output to [`modules/project`](../project/README.md) to keep project-level access synchronized.

## Minimal tenant and intranet app

Deploy a Gemini Enterprise tenant with Google Workspace identity, automatic license registration on `default_user_store`, a hosted web app widget, and app-level user access:

```hcl
module "gemini-enterprise" {
  source     = "./fabric/modules/geap-gemini-enterprise"
  project_id = var.project_id
  location   = "eu"
  idp_config = {
    idp_type = "GSUITE"
  }
  user_store_config = {
    enable_license_auto_register = true
  }
  apps = {
    intranet = {
      engine = {
        display_name = "Employee Intranet"
        company_name = "Example Corp"
      }
      widget_config = {
        access_settings = {
          enable_web_app = true
        }
        ui_settings = {
          interaction_type = "SEARCH_WITH_FOLLOW_UPS"
        }
      }
      iam = {
        "roles/discoveryengine.agentspaceUser" = ["group:${var.group_email}"]
      }
    }
  }
}
# tftest inventory=minimal.yaml
```

## Native data stores and CMEK

Register a location-level CMEK configuration and attach a native ACL-enabled data store with a custom schema to an application. Because Discovery Engine's `UpdateEngine` API rejects `dataStoreIds` lists of length `1`, the module automatically creates an empty `NO_CONTENT` companion store (`<engine_id>-companion`) whenever an app resolves to a single attached store:

```hcl
module "gemini-enterprise" {
  source              = "./fabric/modules/geap-gemini-enterprise"
  project_id          = var.project_id
  location            = "eu"
  prefix              = var.prefix
  deletion_protection = false
  encryption_config = {
    kms_key = "projects/${var.project_id}/locations/eu/keyRings/ge-ring/cryptoKeys/ge-key"
  }
  data_stores = {
    kb = {
      acl_enabled    = true
      app_ids        = ["intranet"]
      content_config = "CONTENT_REQUIRED"
      display_name   = "Internal Knowledge Base"
      json_schema = jsonencode({
        "$schema" = "https://json-schema.org/draft/2020-12/schema"
        type      = "object"
        properties = {
          title = { type = "string" }
        }
      })
      document_processing_config = {
        default_parsing_config = {
          digital_parsing_config = true
        }
      }
    }
  }
  apps = {
    intranet = {
      engine = {
        display_name = "Knowledge Portal"
      }
    }
  }
}
# tftest inventory=data-stores.yaml
```

## SaaS and Custom MCP connectors with Egress Agent Gateway

Attach first-party/third-party SaaS data connectors and Custom MCP servers governed by an [Egress Agent Gateway](../geap-agent-gateway/README.md). Backend-appended connector entities (`root` for `outlook`, `site` for `sharepoint`) are synthesized automatically for zero-diff imports and excluded from engine `dataStoreIds`:

```hcl
module "gemini-enterprise" {
  source               = "./fabric/modules/geap-gemini-enterprise"
  project_id           = var.project_id
  project_number       = var.project_number
  location             = "eu"
  deletion_protection  = false
  egress_agent_gateway = "projects/${var.project_id}/locations/europe-west1/agentGateways/egress-gw"
  oauth_config = {
    auth_uri      = "https://idp.example.com/oauth2/authorize"
    client_id     = "mcp-client-id"
    client_secret = "projects/${var.project_id}/secrets/mcp-secret/versions/1"
    scopes        = ["openid", "email"]
    token_uri     = "https://idp.example.com/oauth2/token"
  }
  data_connectors = {
    sharepoint-corp = {
      app_ids         = ["intranet"]
      connector_modes = ["DATA_INGESTION"]
      data_source     = "sharepoint"
      json_params = jsonencode({
        tenant_id = "00000000-0000-0000-0000-000000000000"
      })
      entities = [
        {
          entity_name = "file"
        }
      ]
    }
  }
  mcp_connectors = {
    bq-tools = {
      app_ids      = ["intranet"]
      display_name = "BigQuery MCP"
      url          = "https://mcp.internal.example.com/mcp"
    }
  }
  apps = {
    intranet = {
      engine = {
        display_name = "Connected Intranet"
      }
    }
  }
}
# tftest inventory=connectors.yaml
```

## Adopting an existing app and managing the default assistant

Creating a Gemini Enterprise `APP_TYPE_INTRANET` engine automatically provisions `default_assistant`, while `google_discovery_engine_assistant` issues a `POST` on create (`409 AlreadyExists`). Leave `assistant = null` on the initial apply, then import `default_assistant` before setting `assistant` (the module enforces `deletion_policy = "ABANDON"` so `default_assistant` is never deleted):

```hcl
import {
  id = "projects/my-project/locations/eu/collections/default_collection/engines/existing-app/assistants/default_assistant"
  to = module.gemini-enterprise.google_discovery_engine_assistant.default["existing-app"]
}
# tftest skip
```

Omit `engine` on an entry in `apps` to adopt a Console-created application while managing its assistant, search widget, gateway binding, and IAM:

```hcl
module "gemini-enterprise" {
  source     = "./fabric/modules/geap-gemini-enterprise"
  project_id = var.project_id
  location   = "eu"
  apps = {
    existing-app = {
      assistant = {
        display_name       = "Enterprise Assistant"
        web_grounding_type = "WEB_GROUNDING_TYPE_GOOGLE_SEARCH"
        banned_phrases = {
          confidential = {
            ignore_diacritics = true
            match_type        = "SIMPLE_STRING_MATCH"
          }
        }
        generation_config = {
          default_language   = "en"
          system_instruction = "Answer concisely using verified internal sources."
        }
        model_armor_config = {
          failure_mode         = "FAIL_CLOSED"
          response_template    = "projects/${var.project_id}/locations/eu/templates/ge-response"
          user_prompt_template = "projects/${var.project_id}/locations/eu/templates/ge-prompt"
        }
      }
      widget_config = {
        access_settings = {
          allow_public_access = false
          allowlisted_domains = ["example.com"]
          enable_web_app      = true
        }
      }
      iam_by_principals = {
        "group:${var.group_email}" = ["roles/discoveryengine.agentspaceUser"]
      }
    }
  }
}
# tftest inventory=adopt-assistant.yaml
```

## Context

Use `context` to interpolate symbolic `$namespace:key` references across project IDs, locations, Workforce Identity pools, license configs, KMS keys, Egress Agent Gateways, Model Armor templates, Secret Manager versions, custom roles, and IAM principals:

```hcl
module "gemini-enterprise" {
  source               = "./fabric/modules/geap-gemini-enterprise"
  project_id           = "$project_ids:main"
  project_number       = var.project_number
  location             = "$locations:primary"
  deletion_protection  = false
  egress_agent_gateway = "$agent_gateways:egress"
  idp_config = {
    idp_type            = "THIRD_PARTY"
    workforce_pool_name = "$workforce_pools:corp"
  }
  user_store_config = {
    default_license_config       = "$license_configs:enterprise"
    enable_license_auto_register = true
  }
  encryption_config = {
    kms_key            = "$kms_keys:eu"
    single_region_keys = ["$kms_keys:ew1"]
  }
  oauth_config = {
    auth_uri      = "https://idp.example.com/oauth2/authorize"
    client_id     = "$secrets:mcp-client-id"
    client_secret = "$secrets:mcp-client-secret"
    token_uri     = "https://idp.example.com/oauth2/token"
  }
  mcp_connectors = {
    tools = {
      app_ids = ["intranet"]
      url     = "https://mcp.internal.example.com/mcp"
    }
  }
  apps = {
    intranet = {
      engine = {
        display_name = "Intranet"
        kms_key      = "$kms_keys:eu"
      }
      assistant = {
        model_armor_config = {
          response_template    = "$model_armor_templates:response"
          user_prompt_template = "$model_armor_templates:prompt"
        }
      }
      widget_config = {
        access_settings = {
          enable_web_app                   = true
          workforce_identity_pool_provider = "$workforce_pools:corp-provider"
        }
      }
      iam = {
        "$custom_roles:ge_viewer" = ["$iam_principals:employees"]
      }
      iam_bindings_additive = {
        contractor-user = {
          member = "$iam_principals:contractors"
          role   = "roles/discoveryengine.agentspaceUser"
        }
      }
    }
  }
  context = {
    agent_gateways = {
      egress = "projects/actual-prj/locations/europe-west1/agentGateways/egress"
    }
    custom_roles = {
      ge_viewer = "projects/actual-prj/roles/geViewer"
    }
    iam_principals = {
      contractors = "group:contractors@example.com"
      employees   = "group:employees@example.com"
    }
    kms_keys = {
      eu  = "projects/kms-prj/locations/eu/keyRings/ring/cryptoKeys/eu-key"
      ew1 = "projects/kms-prj/locations/europe-west1/keyRings/ring/cryptoKeys/ew1-key"
    }
    license_configs = {
      enterprise = "projects/actual-prj/locations/global/licenseConfigs/ent-lic"
    }
    locations = {
      primary = "eu"
    }
    model_armor_templates = {
      prompt   = "projects/actual-prj/locations/eu/templates/prompt"
      response = "projects/actual-prj/locations/eu/templates/response"
    }
    project_ids = {
      main = "actual-prj"
    }
    secrets = {
      mcp-client-id     = "projects/actual-prj/secrets/mcp-id/versions/1"
      mcp-client-secret = "projects/actual-prj/secrets/mcp-secret/versions/1"
    }
    workforce_pools = {
      corp          = "locations/global/workforcePools/corp-pool"
      corp-provider = "locations/global/workforcePools/corp-pool/providers/oidc"
    }
  }
}
# tftest inventory=context.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L156) | Project ID where Gemini Enterprise resources are managed. | <code>string</code> | ✓ |  |
| [apps](variables-apps.tf#L17) | Gemini Enterprise applications, keyed by logical app ID. Omit 'engine' to adopt an existing Console-created app while managing its assistant, widget, gateway binding, and IAM. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [context](variables.tf#L17) | Context-specific interpolations. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_connectors](variables-data-sources.tf#L17) | First-party and third-party SaaS data connectors in the location, keyed by logical connector ID and attached to apps via app_ids. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [data_stores](variables-data-sources.tf#L101) | Native Discovery Engine data stores in the location, keyed by logical store ID and attached to apps via app_ids. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [deletion_protection](variables.tf#L35) | Prevent Terraform from destroying created engines, data stores, schemas, CMEK configs, and data connectors (sets deletion_policy to PREVENT instead of DELETE). | <code>bool</code> |  | <code>true</code> |
| [egress_agent_gateway](variables.tf#L42) | Optional default Egress Agent Gateway resource ID bound to apps unless overridden per app. | <code>string</code> |  | <code>null</code> |
| [encryption_config](variables.tf#L48) | Location-level CMEK configuration registered before stores and engines are created. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [idp_config](variables.tf#L59) | Location-level Discovery Engine identity provider (ACL) configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [location](variables.tf#L84) | Discovery Engine multi-region location (global, us, or eu). | <code>string</code> |  | <code>&#34;eu&#34;</code> |
| [mcp_connectors](variables-data-sources.tf#L207) | Custom MCP server data connectors in the location, keyed by logical connector ID and attached to apps via app_ids. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [oauth_config](variables.tf#L103) | Default OAuth 2.0 configuration for Custom MCP connectors. Can be overridden per connector via mcp_connectors[*].oauth_config. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [prefix](variables.tf#L145) | Optional prefix prepended to created engine, data store, and connector IDs. | <code>string</code> |  | <code>null</code> |
| [project_number](variables.tf#L162) | Optional project number, required when binding an Egress Agent Gateway or routing Custom MCP connectors through it. | <code>string</code> |  | <code>null</code> |
| [user_store_config](variables.tf#L168) | Location-level default_user_store license assignment configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [acl_config](outputs.tf#L17) | Location-level ACL configuration resource. |  |
| [acl_config_id](outputs.tf#L22) | Location-level ACL configuration resource ID. |  |
| [app_iam_principals](outputs.tf#L27) | Deduplicated project-eligible IAM principals granted roles across any Gemini Enterprise app. |  |
| [assistant_ids](outputs.tf#L32) | Managed assistant resource IDs, keyed by app key. |  |
| [assistants](outputs.tf#L39) | Managed assistant resources, keyed by app key. |  |
| [cmek_config](outputs.tf#L44) | Location-level CMEK configuration resource. |  |
| [cmek_config_id](outputs.tf#L49) | Location-level CMEK configuration resource ID. |  |
| [data_connector_ids](outputs.tf#L54) | SaaS data connector resource IDs, keyed by connector key. |  |
| [data_connectors](outputs.tf#L61) | SaaS data connector resources, keyed by connector key. |  |
| [data_store_ids](outputs.tf#L66) | Native data store resource IDs, keyed by store key. |  |
| [data_stores](outputs.tf#L76) | Native data store resources, keyed by store key. |  |
| [engine_ids](outputs.tf#L84) | Created Gemini Enterprise search engine resource IDs, keyed by app key. |  |
| [engines](outputs.tf#L100) | Created Gemini Enterprise search engine resources, keyed by app key. |  |
| [mcp_connector_ids](outputs.tf#L114) | Custom MCP data connector resource IDs, keyed by connector key (or '<connector>/<app>' when expanded across multiple gateway-bound apps). |  |
| [mcp_connectors](outputs.tf#L124) | Custom MCP data connector resources, keyed by connector key (or '<connector>/<app>' when expanded across multiple gateway-bound apps). |  |
| [user_store](outputs.tf#L132) | Location-level default user store resource. |  |
| [user_store_id](outputs.tf#L137) | Location-level default user store resource ID. |  |
| [widget_config_ids](outputs.tf#L142) | Search widget configuration resource IDs, keyed by app key. |  |
| [widget_configs](outputs.tf#L149) | Search widget configuration resources, keyed by app key. |  |
<!-- END TFDOC -->
