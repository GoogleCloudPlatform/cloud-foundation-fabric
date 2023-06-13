outputs_location = "../../fast-config"

composer_config = {
  environment_size = "ENVIRONMENT_SIZE_SMALL"
  software_config = {
    image_version = "composer-2-airflow-2"
    pypi_packages = { 
      apache-airflow-providers-cncf-kubernetes = ""
    }
  }
  workloads_config = {
    scheduler = {
      count = 1
      cpu = 0.5
      memory_gb = 1.875
      storage_gb = 1
    }
    web_server = {
      cpu        = 0.5
      memory_gb  = 1.875
      storage_gb = 1
    }
    worker = {
      cpu        = 0.5
      max_count  = 3
      memory_gb  = 1.875
      min_count  = 1
      storage_gb = 1
    }
  }
}

webserver_access_ip_ranges = [
  {
    description = "AWS VPN NAT 1"
    value       = "52.49.210.75/32"
  },
  {
    description = "AWS VPN NAT 2"
    value       = "18.200.207.149/32"
  },
  {
    description = "AWS VPN NAT 3"
    value       = "34.248.213.44/32"
  }
]
