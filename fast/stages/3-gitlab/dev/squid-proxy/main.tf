################################################################################
##                               Squid resources                               #
################################################################################

locals {
  squid_conf_path = "${path.module}/squid.conf"
}

module "service-account-squid" {
  source            = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/iam-service-account?ref=v22.0.0"
  project_id        = var.project_id
  name              = "svc-squid"
  iam_project_roles = {
    (var.project_id) = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}

module "squid-vm" {
  source             = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/compute-vm?ref=v22.0.0"
  project_id         = var.project_id
  zone               = "${var.region}-b"
  name               = "squid-vm"
  instance_type      = "e2-medium"
  create_template    = false
  network_interfaces = [
    {
      network    = var.network_config.network_self_link
      subnetwork = var.network_config.proxy_subnet_self_link
      nat        = var.enable_public_ip
    }
  ]
  boot_disk = {
    initialize_params = {
      image = "debian-cloud/debian-11"
    }
  }
  service_account        = module.service-account-squid.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  metadata               = {
    startup-script = <<EOF
apt-get update
apt -y install squid
cat <<EOT > /etc/squid/squid.conf
${file(local.squid_conf_path)}
EOF
  }
}
