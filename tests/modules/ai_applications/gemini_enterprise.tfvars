context = {
  iam_principals = {
    users = "group:workforce-users@example.com"
  }
  kms_keys = {
    us = "projects/kms-project/locations/us/keyRings/ring/cryptoKeys/key"
  }
  locations = {
    primary = "us"
  }
  project_ids = {
    app = "actual-project-id"
  }
}
name       = "ge-wif-app"
project_id = "$project_ids:app"
location   = "$locations:primary"
acl_config = {
  idp_type            = "THIRD_PARTY"
  workforce_pool_name = "locations/global/workforcePools/corp-pool"
}
license_config = {
  create_free_trial                  = false
  enable_expired_license_auto_update = true
  enable_license_auto_register       = true
  license_config_name                = "projects/actual-project-id/locations/us/licenseConfigs/enterprise-sub"
}
encryption_configs = {
  us = {
    kms_key = "$kms_keys:us"
  }
}
data_stores_configs = {
  knowledge = {
    content_config              = "CONTENT_REQUIRED"
    create_advanced_site_search = false
    kms_key                     = "$kms_keys:us"
    solution_types              = ["SOLUTION_TYPE_SEARCH"]
  }
}
data_connectors_configs = {
  jira-enterprise = {
    collection_display_name = "Jira Cloud Federated"
    collection_id           = "jira-enterprise-collection"
    connector_modes         = ["FEDERATED", "ACTIONS"]
    data_source             = "jira"
    kms_key                 = "$kms_keys:us"
    params = {
      auth_type    = "OAUTH"
      instance_uri = "https://example.atlassian.net"
      instance_id  = "00000000-0000-0000-0000-000000000000"
      client_id    = "jira-oauth-client-id"
    }
    destination_configs = [
      {
        key = "url"
        destinations = [
          {
            host = "example.atlassian.net"
            port = 443
          }
        ]
        params = "{\"destination_type\":\"public\"}"
      }
    ]
    action_config = {
      create_bap_connection = true
      action_params = {
        auth_type    = "OAUTH"
        instance_uri = "https://example.atlassian.net"
      }
    }
    bap_config = {
      supported_connector_modes = ["ACTIONS"]
      enabled_actions           = ["create_issue", "add_comment"]
    }
    entities = [
      { entity_name = "project" },
      { entity_name = "issue" }
    ]
  }
}
engines_configs = {
  data_store_ids = ["knowledge"]
  search_engine_config = {
    app_type                       = "APP_TYPE_INTRANET"
    company_name                   = "Example Corp"
    display_name                   = "Gemini Enterprise WIF"
    enable_private_knowledge_graph = true
    kms_key                        = "$kms_keys:us"
    search_add_ons                 = ["SEARCH_ADD_ON_LLM"]
    search_tier                    = "SEARCH_TIER_ENTERPRISE"
    features = {
      "model-selector"  = "FEATURE_STATE_ON"
      "workflow-agents" = "FEATURE_STATE_ON"
    }
    iam = {
      "roles/discoveryengine.agentspaceUser" = ["$iam_principals:users"]
    }
    widget_config = {
      enable_web_app                   = true
      workforce_identity_pool_provider = "locations/global/workforcePools/corp-pool/providers/oidc-provider"
    }
  }
}
