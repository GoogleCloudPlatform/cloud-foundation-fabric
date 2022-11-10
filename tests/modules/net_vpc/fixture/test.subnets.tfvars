subnet_iam = {
  "europe-west1/a" = {
    "roles/compute.networkUser" = [
      "user:a@example.com", "group:g-a@example.com"
    ]
  }
  "europe-west1/c" = {
    "roles/compute.networkUser" = [
      "user:c@example.com", "group:g-c@example.com"
    ]
  }
}
subnets = [
  {
    name          = "a"
    region        = "europe-west1"
    ip_cidr_range = "10.0.0.0/24"
  },
  {
    name                  = "b"
    region                = "europe-west1"
    ip_cidr_range         = "10.0.1.0/24",
    description           = "Subnet b"
    enable_private_access = false
  },
  {
    name          = "c"
    region        = "europe-west1"
    ip_cidr_range = "10.0.2.0/24"
    secondary_ip_ranges = {
      a = "192.168.0.0/24"
      b = "192.168.1.0/24"
    }
  },
  {
    name          = "d"
    region        = "europe-west1"
    ip_cidr_range = "10.0.3.0/24"
    flow_logs_config = {
      flow_sampling        = 0.5
      aggregation_interval = "INTERVAL_10_MIN"
    }
  }
]
