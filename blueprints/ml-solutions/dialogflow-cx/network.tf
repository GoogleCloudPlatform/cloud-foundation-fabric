# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# tfdoc:file:description Network resources.

module "vpc" {
  source     = "../../../modules/net-vpc"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.project.project_id
  name       = "${var.prefix}-vpc"
  subnets = [
    {
      ip_cidr_range = "10.10.0.0/24"
      name          = "service"
      region        = var.region
    },
    {
      ip_cidr_range = "10.10.20.0/28"
      name          = "connector"
      region        = var.region
    }
  ]
  subnets_proxy_only = [
    {
      ip_cidr_range = "10.10.10.0/24"
      name          = "proxy"
      region        = var.region
    }
  ]
}

module "vpc-firewall" {
  source     = "../../../modules/net-vpc-firewall"
  count      = local.use_shared_vpc ? 0 : 1
  project_id = module.project.project_id
  network    = module.vpc.0.name
  default_rules_config = {
    admin_ranges = ["10.10.0.0/24", "10.10.10.0/24", "10.10.20.0/28"]
  }
}

module "nat" {
  count          = local.use_shared_vpc ? 0 : 1
  source         = "../../../modules/net-cloudnat"
  project_id     = module.project.project_id
  name           = "${var.prefix}-nat"
  region         = var.region
  router_network = module.vpc.0.name
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "default" {
  private_key_pem = tls_private_key.default.private_key_pem
  subject {
    common_name = "webhook-2bp66dygaa-ew.a.run.app" # trim(module.cloud_run.service.status.0.url, "https://")
  }
  dns_names             = ["webhook-2bp66dygaa-ew.a.run.app"] #trim(module.cloud_run.service.status.0.url, "https://")]
  validity_period_hours = 36500
  allowed_uses          = ["any_extended"]
  set_subject_key_id    = true
}

module "ilb-l7" {
  source     = "../../../modules/net-lb-app-int"
  name       = "ilb-test"
  project_id = module.project.project_id
  region     = var.region
  backend_service_configs = {
    default = {
      backends = [{
        group = "webhook"
      }]
      health_checks = []
    }
  }
  health_check_configs = {}
  neg_configs = {
    webhook = {
      cloudrun = {
        region = var.region
        target_service = {
          name = "webhook"
        }
      }
    }
  }
  vpc_config = {
    network    = local.vpc
    subnetwork = local.subnets["service"]
  }
  protocol = "HTTPS"
  ssl_certificates = {
    create_configs = {
      ssl = {
        certificate = tls_self_signed_cert.default.cert_pem
        private_key = tls_private_key.default.private_key_pem
      }
    }
  }
  depends_on = [module.vpc]
}

resource "local_file" "crt" {
  content  = tls_self_signed_cert.default.cert_pem
  filename = "${path.module}/server_tf.crt"
}


resource "null_resource" "der" {
  triggers = {
    script_hash = "${sha256("server_tf.crt")}"
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = "openssl  x509 -in server_tf.crt -out server_tf.der -outform DER"
  }
  depends_on = [local_file.crt]
}
