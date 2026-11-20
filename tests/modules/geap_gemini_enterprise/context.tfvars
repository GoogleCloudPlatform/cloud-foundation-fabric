project_id           = "$project_ids:main"
project_number       = "123456789012"
location             = "$locations:primary"
prefix               = "corp"
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

data_stores = {
  kb = {
    acl_enabled = true
    app_ids     = ["intranet"]
    kms_key     = "$kms_keys:eu"
  }
}

data_connectors = {
  outlook-corp = {
    app_ids     = ["intranet"]
    data_source = "outlook"
    kms_key     = "$kms_keys:eu"
    entities = [
      {
        entity_name = "mail"
      }
    ]
  }
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
      ui_settings = {
        data_store_ui_configs = {
          kb = {
            facet_fields = {
              department = "Department"
            }
          }
        }
      }
    }
    iam = {
      "$custom_roles:ge_viewer" = [
        "$iam_principals:employees",
        "allAuthenticatedUsers",
      ]
    }
    iam_bindings = {
      analysts-bind = {
        members = ["$iam_principals:analysts"]
        role    = "roles/discoveryengine.agentspaceUser"
      }
    }
    iam_bindings_additive = {
      contractors-member = {
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
    analysts    = "group:analysts@example.com"
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
