automation = {
  outputs_bucket = "test"
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
    vpc_config = {
      subnetwork             = "projects/prj-host/regions/europe-west1/subnetworks/gke-0"
      master_ipv4_cidr_block = "172.16.20.0/28"
    }
  }
}
nodepools = {
  mycluster = {
    mynodepool = {
      node_count = { initial = 1 }
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
