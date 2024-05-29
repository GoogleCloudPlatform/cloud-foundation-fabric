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
  wl_templates_path = (
    var.templates_path == null
    ? "${path.module}/manifest-templates"
    : pathexpand(var.templates_path)
  )
}

resource "kubectl_manifest" "kong-namespace" {
  yaml_body = templatefile(
    "${local.wl_templates_path}/namespace.yaml", {
      kong_namespace = var.namespace
    }
  )
}

resource "kubectl_manifest" "kong-license" {
  yaml_body = templatefile(
    "${local.wl_templates_path}/license.yaml", {
      kong_namespace = var.namespace
      kong_license   = "'{}'"
    }
  )
  depends_on = [kubectl_manifest.kong-namespace]
}

resource "kubectl_manifest" "kong-cert" {
  yaml_body = templatefile(
    "${local.wl_templates_path}/cert.yaml", {
      kong_namespace = var.namespace
      certificate    = base64encode(tls_self_signed_cert.kong.cert_pem)
      private_key    = base64encode(tls_self_signed_cert.kong.private_key_pem)
    }
  )
  depends_on = [kubectl_manifest.kong-license]
}

resource "helm_release" "kong-cp" { # Kong Gateway control plane release
  name       = "kong-cp"
  repository = "https://charts.konghq.com"
  chart      = "kong"
  namespace  = var.namespace
  values     = [file("${local.wl_templates_path}/values-cp.yaml")]
  depends_on = [kubectl_manifest.kong-cert]
}

resource "helm_release" "kong-dp" { # Kong Gateway data plane release
  name       = "kong-dp"
  repository = "https://charts.konghq.com"
  chart      = "kong"
  namespace  = var.namespace
  values     = [file("${local.wl_templates_path}/values-dp.yaml")]
  depends_on = [kubectl_manifest.kong-cert]
}

resource "kubectl_manifest" "kong-config" {
  yaml_body = templatefile(
    "${local.wl_templates_path}/config-proxy.yaml", {
      kong_namespace = var.namespace
      root_cer       = indent(4, google_privateca_certificate_authority.default.pem_ca_certificates[0])
      domain         = var.custom_domain
    }
  )
  depends_on = [helm_release.kong-cp]
}

resource "kubectl_manifest" "kong-configure" {
  yaml_body = templatefile(
    "${local.wl_templates_path}/configure-proxy.yaml", {
      kong_namespace = var.namespace
    }
  )
  depends_on = [kubectl_manifest.kong-config]
}