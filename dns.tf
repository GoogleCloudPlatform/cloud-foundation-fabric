resource "google_dns_response_policy" "default" {
  response_policy_name = "google-apis-private-policy"
  description          = "Resolve Google API FQDNs to private API IPs."
  project              = var.project_id

  # DMZ VPC
  networks {
    network_url = "ID_OF_VPC_WIP"
  }

  # non DMZ VPC
  networks {
    network_url = "ID_OF_VPC_WIP"
  }
}

resource "google_dns_response_policy_rule" "default" {
  for_each        = var.dns_policy_rules
  rule_name       = each.key
  project         = var.project_id
  response_policy = google_dns_response_policy.default.id
  dns_name        = each.value.dns_name

  dynamic "local_data" {
    for_each = length(each.value.local_data) == 0 ? [] : [""]
    content {
      dynamic "local_datas" {
        for_each = each.value.local_data
        iterator = data
        content {
          # setting name to something different seems to have no effect
          # so we comply with the console UI and set it to the rule dns name
          # name    = split(" ", data.key)[1]
          # type    = split(" ", data.key)[0]
          name    = each.value.dns_name
          type    = data.key
          ttl     = data.value.ttl
          rrdatas = data.value.rrdatas
        }
      }
    }
  }
}
