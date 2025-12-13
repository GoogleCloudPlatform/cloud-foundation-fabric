automation = {
  outputs_bucket = "fast2-prod-iac-core-outputs"
}
billing_account = {
  id = "012345-67890A-BCDEF0",
}
clusters = {
  mycluster = {
    cluster_autoscaling = null
    description         = "my cluster"
    dns_domain          = null
    location            = "europe-west1"
    labels              = {}
    private_cluster_config = {
      enable_private_endpoint = true
      master_global_access    = true
    }
    access_config = {
      dns_access = true
      ip_access = {
        disable_public_endpoint = true
      }
      private_nodes = true
    }
    enable_features = {
      binary_authorization = true
      database_encryption = {
        state    = "ENCRYPTED"
        key_name = "projects/prj-host/locations/europe-west1/keyRings/dev-primary-default/cryptoKeys/gke"
      }
      groups_for_rbac      = "gke-security-groups@google.com"
      intranode_visibility = true
      rbac_binding_config = {
        enable_insecure_binding_system_unauthenticated : false
        enable_insecure_binding_system_authenticated : false
      }
      shielded_nodes = true
      upgrade_notifications = {
        event_types  = ["SECURITY_BULLETIN_EVENT", "UPGRADE_AVAILABLE_EVENT", "UPGRADE_INFO_EVENT", "UPGRADE_EVENT"]
        kms_key_name = "projects/prj-host/locations/europe-west1/keyRings/dev-primary-default/cryptoKeys/gke"
      }
      workload_identity = true
    }
    node_config = {
      boot_disk_kms_key = "projects/prj-host/locations/europe-west1/keyRings/dev-primary-default/cryptoKeys/gke"
    }
    vpc_config = {
      subnetwork             = "projects/prj-host/regions/europe-west1/subnetworks/gke-0"
      master_ipv4_cidr_block = "172.16.20.0/28"
      master_ipv4_cidr_block = "172.16.20.0/28"
      master_authorized_ranges = {
        private = "10.0.0.0/24"
      }
    }
  }
}
environments = {
  dev = {
    name = "Development"
  }
}
nodepools = {
  mycluster = {
    mynodepool = {
      node_count = { initial = 1 }
      node_config = {
        sandbox_config_gvisor = true
        boot_disk_kms_key     = "projects/prj-host/locations/europe-west1/keyRings/dev-primary-default/cryptoKeys/gke"
        shielded_instance_config = {
          enable_integrity_monitoring = true
          enable_secure_boot          = true
        }
      }
    }
  }
}
folder_ids = {
  gke-dev = "folders/12345678"
}
host_project_ids = {
  dev-spoke-0 = "fast-dev-net-spoke-0"
}
prefix = "fast"
vpc_self_links = {
  dev-spoke-0 = "projects/fast-dev-net-spoke-0/global/networks/dev-spoke-0"
}
