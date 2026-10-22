context = {
  kms_keys = {
    eu = "projects/kms-project/locations/eu/keyRings/ring/cryptoKeys/key"
  }
  locations = {
    agent   = "europe-west1"
    primary = "eu"
  }
  project_ids = {
    app = "actual-project-id"
  }
}
name       = "my-chat-app"
project_id = "$project_ids:app"
location   = "$locations:primary"
encryption_configs = {
  eu = {
    kms_key = "$kms_keys:eu"
  }
}
data_stores_configs = {
  data-store-1 = {
    kms_key        = "$kms_keys:eu"
    location       = "$locations:primary"
    solution_types = ["SOLUTION_TYPE_CHAT"]
  }
}
engines_configs = {
  data_store_ids = ["data-store-1"]
  location       = "$locations:primary"
  chat_engine_config = {
    agent_config = {
      location = "$locations:agent"
    }
    company_name = "Example"
  }
}
