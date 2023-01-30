# Cloud Run service
module "cloud_run" {
  source     = "../../../modules/cloud-run"
  project_id = var.project_id
  name       = var.run_svc_name
  region     = var.region
  containers = [{
    image         = var.image
    options       = null
    ports         = null
    resources     = null
    volume_mounts = null
  }]
  iam = {
    "roles/run.invoker" = ["allUsers"]
  }
  ingress_settings = var.ingress_settings
}

# Reserved static IP for the Load Balancer
resource "google_compute_global_address" "default" {
  count   = var.glb_create ? 1 : 0
  project = var.project_id
  name    = "glb-ip"
}

# Global L7 HTTPS Load Balancer in front of Cloud Run
module "glb" {
  source     = "../../../modules/net-glb"
  count      = var.glb_create ? 1 : 0
  project_id = var.project_id
  name       = "glb"
  address    = google_compute_global_address.default[0].address
  backend_service_configs = {
    default = {
      backends = [
        { backend = "neg-0" }
      ]
      health_checks   = []
      port_name       = "http"
      security_policy = try(google_compute_security_policy.policy[0].name, null)
    }
  }
  health_check_configs = {}
  neg_configs = {
    neg-0 = {
      cloudrun = {
        region = var.region
        target_service = {
          name = var.run_svc_name
        }
      }
    }
  }
  protocol = "HTTPS"
  ssl_certificates = {
    managed_configs = {
      default = {
        domains = [var.custom_domain]
      }
    }
  }
}

resource "google_compute_security_policy" "policy" {
  count   = var.glb_create ? (var.security_policy.enabled ? 1 : 0) : 0
  name    = "cloud-run-policy"
  project = var.project_id
  rule {
    action   = "deny(403)"
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.security_policy.ip_blacklist
      }
    }
    description = "Deny access to list of IPs"
  }
  rule {
    action   = "deny(403)"
    priority = 900
    match {
      expr {
        expression = "request.path.matches(\"${var.security_policy.path_blocked}\")"
      }
    }
    description = "Deny access to specific URL paths"
  }
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule"
  }
}
