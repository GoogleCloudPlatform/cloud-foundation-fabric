resource "kubectl_manifest" "kong-namespace" {
  yaml_body = templatefile(
    "${local.wl_templates_path}/namespace.yaml",
    local.manifest_template_parameters
  )
}

resource "kubectl_manifest" "kong-license" {
  yaml_body = templatefile(
    "${local.wl_templates_path}/license.yaml",
    local.manifest_template_parameters
  )
  depends_on = [kubectl_manifest.kong-namespace]
}

resource "kubectl_manifest" "kong-cert" {
  yaml_body = templatefile(
    "${local.wl_templates_path}/cert.yaml",
    local.manifest_template_parameters
  )
  depends_on = [kubectl_manifest.kong-license]
}

resource "helm_release" "kong-cp" { # Kong Gateway control plane release
  name       = "kong-cp"
  repository = "https://charts.konghq.com"
  chart      = "kong"
  namespace  = var.namespace
  values     = [file("${local.wl_templates_path}/values-cp.yaml")]
  //timeout    = "1800"
  depends_on = [kubectl_manifest.kong-cert]
}

resource "helm_release" "kong-dp" { # Kong Gateway data plane release
  name       = "kong-dp"
  repository = "https://charts.konghq.com"
  chart      = "kong"
  namespace  = var.namespace
  values     = [file("${local.wl_templates_path}/values-dp.yaml")]
  //timeout    = "1800"
  depends_on = [kubectl_manifest.kong-cert]
}