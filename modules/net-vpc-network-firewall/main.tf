locals {
  _files = try(flatten(
    [
      for config_path in var.data_folders :
      concat(
        [
          for config_file in fileset("${path.root}/${config_path}", "**/*.yaml") :
          "${path.root}/${config_path}/${config_file}"
        ]
      )

    ]
  ), null)

  _files_rules = try(merge(
    [
      for config_file in local._files :
      try(yamldecode(file(config_file)), {})
    ]...
  ), null)

  firewall_rules = merge(try(local._files_rules, {}), try(var.firewall_rules, {}))


  rules = { for k, v in local.firewall_rules : k => {
    deployment              = try(v.deployment, "global")
    disabled                = try(v.disabled, false)
    description             = try(v.description, null)
    action                  = try(v.action, "allow")
    direction               = try(upper(v.direction), "INGRESS")
    priority                = try(v.priority, 1000)
    enable_logging          = try(v.enable_logging, false)
    ip_protocol             = try(v.ip_protocol, "all")
    ports                   = try(v.ports, null)
    target_service_accounts = try(v.target_service_accounts, null)
    dest_ip_ranges          = try(v.dest_ip_ranges, null)
    src_ip_ranges           = try(v.src_ip_ranges, null)
    src_secure_tags         = try(flatten([for k in data.google_tags_tag_value.src_secure_tags : k.id]), null)
    target_secure_tags      = try(flatten([for k in data.google_tags_tag_value.target_secure_tags : k.id]), null)


  } }

  src_secure_tags    = try(flatten([for k, v in local.firewall_rules : v.src_secure_tags]), null)    # used for data resource
  target_secure_tags = try(flatten([for k, v in local.firewall_rules : v.target_secure_tags]), null) # used for data resource

}


data "google_tags_tag_value" "src_secure_tags" {
  for_each   = try({ for k, v in local.src_secure_tags : k => v }, {})
  parent     = var.parent_tag
  short_name = each.value
}


data "google_tags_tag_value" "target_secure_tags" {
  for_each   = try({ for k, v in local.target_secure_tags : k => v }, {})
  parent     = var.parent_tag
  short_name = each.value
}


######----Global Network Firewall Policy----######

resource "google_compute_network_firewall_policy" "default" {
  count       = contains([for k, v in local.firewall_rules : v.deployment], "global") ? 1 : 0
  name        = var.global_policy_name
  project     = var.project_id
  description = "Global network firewall policy"
}

resource "google_compute_network_firewall_policy_rule" "default" {
  for_each        = { for k, v in local.rules : k => v if v.deployment == "global" }
  project         = var.project_id
  firewall_policy = google_compute_network_firewall_policy.default[0].name
  rule_name       = each.key
  disabled        = each.value["disabled"]
  action          = each.value["action"]
  direction       = each.value["direction"]
  priority        = each.value["priority"]
  description     = each.value["description"]
  enable_logging  = each.value["enable_logging"]

  match {

    dynamic "src_secure_tags" {
      for_each = each.value.src_secure_tags
      content {
        name = src_secure_tags.value
      }

    }

    dest_ip_ranges = each.value["dest_ip_ranges"]
    src_ip_ranges  = each.value["src_ip_ranges"]
    layer4_configs {
      ip_protocol = each.value["ip_protocol"]
      ports       = each.value["ports"]
    }
  }

  target_service_accounts = each.value["target_service_accounts"]


  dynamic "target_secure_tags" {
    for_each = each.value.target_secure_tags
    content {
      name = target_secure_tags.value
    }

  }

}

resource "google_compute_network_firewall_policy_association" "default" {

  count             = var.global_network != null ? 1 : 0
  name              = "association"
  attachment_target = var.global_network
  firewall_policy   = google_compute_network_firewall_policy.default[0].name
  project           = var.project_id
}

####----Regional Network Firewall Policy----######

resource "google_compute_region_network_firewall_policy" "default" {
  count       = contains([for k, v in local.firewall_rules : v.deployment], "regional") ? 1 : 0
  name        = var.regional_policy_name
  project     = var.project_id
  description = "Regional network firewall policy"
  region      = var.firewall_policy_region
}

resource "google_compute_region_network_firewall_policy_rule" "default" {
  for_each        = { for k, v in local.rules : k => v if v.deployment == "regional" }
  project         = var.project_id
  firewall_policy = google_compute_region_network_firewall_policy.default[0].name
  region          = var.firewall_policy_region
  rule_name       = each.key
  disabled        = each.value["disabled"]
  action          = each.value["action"]
  direction       = each.value["direction"]
  priority        = each.value["priority"]
  description     = each.value["description"]
  enable_logging  = each.value["enable_logging"]

  match {

    dynamic "src_secure_tags" {
      for_each = each.value.src_secure_tags
      content {
        name = src_secure_tags.value
      }

    }

    dest_ip_ranges = each.value["dest_ip_ranges"]
    src_ip_ranges  = each.value["src_ip_ranges"]
    layer4_configs {
      ip_protocol = each.value["ip_protocol"]
      ports       = each.value["ports"]
    }
  }
  target_service_accounts = each.value["target_service_accounts"]

  dynamic "target_secure_tags" {
    for_each = each.value.target_secure_tags
    content {
      name = target_secure_tags.value
    }

  }


}

resource "google_compute_region_network_firewall_policy_association" "default" {
  count             = var.regional_network != null ? 1 : 0
  name              = "association"
  attachment_target = var.regional_network
  firewall_policy   = google_compute_region_network_firewall_policy.default[0].name
  project           = var.project_id
  region            = "var.firewall_policy_region"
}

