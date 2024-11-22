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
  bindplane_password = coalesce(var.bindplane_secrets.password, try(random_password.password.0.result, null))
}

resource "random_password" "password" {
  count            = var.bindplane_secrets.password == null ? 1 : 0
  length           = 16
  special          = true
  override_special = "_!%^"
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = "bindplane"
  }
}

resource "kubernetes_secret" "bindplane_secret" {
  metadata {
    name      = "bindplane"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }

  data = {
    username        = var.bindplane_secrets.user
    password        = local.bindplane_password
    sessions_secret = var.bindplane_secrets.sessions_secret
    license         = var.bindplane_secrets.license
  }
  type = "Opaque"
}

resource "kubernetes_secret" "tls" {
  metadata {
    name      = "bindplane-tls"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }
  data = {
    "tls.crt" = var.bindplane_tls.cer
    "tls.key" = var.bindplane_tls.key
  }
  type = "kubernetes.io/tls"
}
