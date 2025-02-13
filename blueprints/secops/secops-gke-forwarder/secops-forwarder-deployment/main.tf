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
  _chronicle_forwarder_default_lb_ports = [
    "2001", "2011", "2021", "2031", "2041", "2051", "2061", "2071"
  ]
  chronicle_forwarder_config = {
    for key, value in var.tenants : key =>
    coalesce(value.forwarder_config.config_file_content, try(templatefile("${path.module}/data/default-config.yaml.tpl", {
      chronicle_url = "${value.chronicle_region}-malachiteingestion-pa.googleapis.com:443",
      customer_id   = value.forwarder_config.customer_id
      collector_id  = value.forwarder_config.collector_id
      secret_key    = value.forwarder_config.secret_key
      tls_required  = value.forwarder_config.tls_config.required
    }), null))
  }
  deployment_names = {
    for key, value in var.tenants : key => "cfps-${value.tenant_id}"
  }
  tenants_exposing_service_attachments = {
    for key, value in var.tenants : key => value if value.network_config.expose_service_attachment
  }
  tenants_exposing_udp_service_attachments = {
    for key, value in var.tenants : key => value if value.network_config.expose_service_attachment && value.forwarder_config.tls_config == null
  }
  tenants_chronicle_forwarder_lb_ports = {
    for k, v in var.tenants : k => coalesce(v.network_config.load_balancer_ports, local._chronicle_forwarder_default_lb_ports)
  }
  tenants_secret_tls = {
    for k, v in var.tenants : k => {
      cer = try(tls_locally_signed_cert.forwarder_server_singed_cert[k].cert_pem, v.forwarder_config.tls_config.cert_pub)
      key = try(tls_private_key.forwarder_server_key[k].private_key_pem, v.forwarder_config.tls_config.cert_key)
    } if v.forwarder_config.tls_config.required
  }
}

resource "kubernetes_namespace" "namespace" {
  for_each = var.tenants
  metadata {
    name = each.value.namespace
  }
}

resource "kubernetes_service" "service_tcp" {
  for_each = var.tenants
  metadata {
    name      = "cfps-${each.value.tenant_id}-tcp"
    namespace = kubernetes_namespace.namespace[each.key].metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = local.deployment_names[each.key]
    }
    type = "LoadBalancer"
    port {
      name        = "hc"
      protocol    = "TCP"
      port        = 8080
      target_port = 8080
    }
    dynamic "port" {
      for_each = local.tenants_chronicle_forwarder_lb_ports[each.key]
      content {
        name        = "tcp-${port.value}"
        protocol    = "TCP"
        port        = port.value
        target_port = port.value
      }
    }
  }
  timeouts {
    create = "5m"
  }
}

resource "kubectl_manifest" "service_attachment_tcp" {
  for_each = local.tenants_exposing_service_attachments
  yaml_body = templatefile("${path.module}/manifests/service-attachment.yaml", {
    tenant       = each.value.tenant_id
    namespace    = kubernetes_namespace.namespace[each.key].metadata[0].name
    service_name = kubernetes_service.service_tcp[each.key].metadata[0].name
  })
  timeouts {
    create = "5m"
  }
}

resource "kubernetes_service" "service_udp" {
  for_each = { for k, v in var.tenants : k => v if v.forwarder_config.tls_config != null }
  metadata {
    name      = "cfps-${each.value.tenant_id}-udp"
    namespace = kubernetes_namespace.namespace[each.key].metadata[0].name
    annotations = {
      "networking.gke.io/load-balancer-type" = "Internal"
    }
  }
  spec {
    selector = {
      app = local.deployment_names[each.key]
    }
    type = "LoadBalancer"
    dynamic "port" {
      for_each = local.tenants_chronicle_forwarder_lb_ports[each.key]
      content {
        name        = "udp-${port.value}"
        protocol    = "UDP"
        port        = port.value
        target_port = port.value
      }
    }
  }
}

resource "kubectl_manifest" "service_attachment_udp" {
  for_each = local.tenants_exposing_udp_service_attachments
  yaml_body = templatefile("${path.module}/manifests/service-attachment.yaml", {
    tenant       = each.value.tenant_id
    namespace    = kubernetes_namespace.namespace[each.key].metadata[0].name
    service_name = kubernetes_service.service_udp[each.key].metadata[0].name
  })
  timeouts {
    create = "5m"
  }
}

resource "kubernetes_deployment" "cfps" {
  for_each = var.tenants
  metadata {
    name      = local.deployment_names[each.key]
    namespace = kubernetes_namespace.namespace[each.key].metadata[0].name
    labels = {
      app = local.deployment_names[each.key]
    }
  }
  spec {
    replicas = 2 # default number of pods
    selector {
      match_labels = {
        app = local.deployment_names[each.key]
      }
    }
    template {
      metadata {
        labels = {
          app = local.deployment_names[each.key]
        }
      }
      spec {
        container {
          name              = "cfps"
          image             = "gcr.io/chronicle-container/${var.tenants[each.key].chronicle_forwarder_image}"
          image_pull_policy = "IfNotPresent"

          resources {
            requests = {
              cpu    = "2"   # 2 CPUs requested
              memory = "2Gi" # 2 GB of RAM requested
            }
            limits = {
              cpu    = "4"   # 4 CPUs limit
              memory = "6Gi" # 4 GB of RAM limit
            }
          }

          volume_mount {
            mount_path = "/opt/chronicle/external/"
            name       = kubernetes_secret.secret_config[each.key].metadata[0].name
            read_only  = true
          }
          dynamic "volume_mount" {
            for_each = try(kubernetes_secret.tls[each.key], null) != null ? [""] : []
            content {
              mount_path = "/opt/chronicle/external/certs"
              name       = kubernetes_secret.tls[each.key].metadata[0].name
              read_only  = true
            }
          }
          liveness_probe {
            http_get {
              path = "/meta/available"
              port = 8080
            }
            failure_threshold = 3
            period_seconds    = 30
          }
          readiness_probe {
            http_get {
              path = "/meta/ready"
              port = 8080
            }
            failure_threshold = 1
            period_seconds    = 30
          }
        }
        volume {
          name = kubernetes_secret.secret_config[each.key].metadata[0].name
          secret {
            secret_name = kubernetes_secret.secret_config[each.key].metadata[0].name
          }
        }
        dynamic "volume" {
          for_each = try(kubernetes_secret.tls[each.key], null) != null ? [""] : []
          content {
            name = kubernetes_secret.tls[each.key].metadata[0].name
            secret {
              secret_name = kubernetes_secret.tls[each.key].metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "cfps" {
  for_each = var.tenants
  metadata {
    name      = "${local.deployment_names[each.key]}-hpa"
    namespace = kubernetes_namespace.namespace[each.key].metadata[0].name
  }
  spec {
    scale_target_ref {
      kind = "Deployment"
      name = kubernetes_deployment.cfps[each.key].metadata[0].name
    }

    min_replicas = 2 # Minimum number of pods
    max_replicas = 5 # Maximum allowed replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = "80"
        }
      }
    }
  }
}

resource "kubernetes_secret" "secret_config" {
  for_each = var.tenants
  metadata {
    name      = "cfps-secret-config-${each.key}"
    namespace = kubernetes_namespace.namespace[each.key].metadata[0].name
  }
  data = {
    "config.conf" = local.chronicle_forwarder_config[each.key]
  }
  type = "Opaque"
}

resource "kubernetes_secret" "tls" {
  for_each = local.tenants_secret_tls
  metadata {
    name      = "cfps-secret-tls-${each.key}"
    namespace = kubernetes_namespace.namespace[each.key].metadata[0].name
  }
  data = {
    "tls.crt" = each.value.cer
    "tls.key" = each.value.key
  }
  type = "kubernetes.io/tls"
}
