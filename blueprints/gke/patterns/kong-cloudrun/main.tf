/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  cloudrun_svcnames = ["svc1", "svc2"]
  manifest_template_parameters = {
    kong_namespace = var.namespace
    kong_license   = "'{}'"
    certificate    = base64encode(tls_self_signed_cert.kong.cert_pem)
    private_key    = base64encode(tls_self_signed_cert.kong.private_key_pem)
  }
  wl_templates_path = (
    var.templates_path == null
    ? "${path.module}/manifest-templates"
    : pathexpand(var.templates_path)
  )
}

# TLS certificate to secure the control plane/data plane Kong communication
resource "tls_private_key" "kong" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "kong" {
  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
  private_key_pem       = tls_private_key.kong.private_key_pem
  validity_period_hours = 1095 * 24
  is_ca_certificate     = true
  subject {
    common_name = "kong_clustering"
  }
}

data "google_compute_network" "host-network" {
  name    = var.created_resources.vpc_name
  project = var.project_id
}

data "google_compute_subnetwork" "host-subnetwork" {
  name    = var.created_resources.subnet_name
  project = var.project_id
  region  = var.region
}

module "service-project" {
  source          = "../../../../modules/project"
  for_each        = var.project_configs
  name            = each.value.project_id
  prefix          = var.prefix
  project_create  = each.value.billing_account_id != null
  billing_account = try(each.value.billing_account_id, null)
  parent          = try(each.value.parent, null)
  services = [
    "compute.googleapis.com",
    "run.googleapis.com",
  ]
  shared_vpc_service_config = {
    host_project = var.project_id
    //service_iam_grants = module.service-project[each.key].services
  }
  skip_delete = true
}