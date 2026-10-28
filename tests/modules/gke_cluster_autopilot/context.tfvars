context = {
  bigquery_datasets = {
    usage = "gke_usage"
  }
  cidr_ranges = {
    home   = "192.168.0.0/16"
    master = "172.16.20.0/28"
  }
  email_addresses = {
    rbac = "gke-security-groups@example.com"
  }
  iam_principals = {
    node-sa = "nodes@my-project.iam.gserviceaccount.com"
  }
  kms_keys = {
    default = "projects/my-project/locations/europe-west8/keyRings/kr/cryptoKeys/k"
  }
  locations = {
    primary   = "europe-west8"
    primary-b = "europe-west8-b"
  }
  networks = {
    default = "projects/my-project/global/networks/vpc"
  }
  project_ids = {
    default = "my-project"
    dr      = "my-dr-project"
  }
  pubsub_topics = {
    upgrades = "projects/my-project/topics/gke-upgrades"
  }
  subnets = {
    default = "projects/my-project/regions/europe-west8/subnetworks/gke"
  }
  tag_values = {
    env = "tagValues/123456789"
  }
}

project_id     = "$project_ids:default"
name           = "cluster-1"
location       = "$locations:primary"
node_locations = ["$locations:primary-b"]
fleet_project  = "$project_ids:default"

access_config = {
  ip_access = {
    authorized_ranges = {
      home = "$cidr_ranges:home"
    }
  }
  master_ipv4_cidr_block = "$cidr_ranges:master"
}

enable_addons = {
  agent_sandbox = true
}

enable_features = {
  database_encryption = {
    state    = "ENCRYPTED"
    key_name = "$kms_keys:default"
  }
  groups_for_rbac       = "$email_addresses:rbac"
  managed_opentelemetry = true
  resource_usage_export = {
    dataset = "$bigquery_datasets:usage"
  }
  upgrade_notifications = {
    topic_id = "$pubsub_topics:upgrades"
  }
}

node_config = {
  boot_disk_kms_key = "$kms_keys:default"
  service_account   = "$iam_principals:node-sa"
  resource_manager_tags = {
    env = "$tag_values:env"
  }
}

vpc_config = {
  network    = "$networks:default"
  subnetwork = "$subnets:default"
  secondary_range_names = {
    pods     = "pods"
    services = "services"
  }
}

backup_configs = {
  enable_backup_agent = true
  backup_plans = {
    backup-1 = {
      encryption_key = "$kms_keys:default"
      schedule       = "0 9 * * 1"
    }
  }
  restore_channels = {
    dr = {
      destination_project = "$project_ids:dr"
    }
  }
}
