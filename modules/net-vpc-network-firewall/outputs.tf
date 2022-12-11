output "global_network_association" {
  description = "Global association name"
  value       = try(google_compute_network_firewall_policy_association.default[0].id, null)
}

output "global_rules" {
  description = "Global rules."
  value       = try([for k in google_compute_network_firewall_policy_rule.default : k.id], null)
}

output "global_policy_name" {
  description = "Global network firewall policy name"
  value       = try(google_compute_network_firewall_policy.default[0].id, null)
}

output "regional_network_association" {
  description = "Global association name"
  value       = try(google_compute_region_network_firewall_policy_association.default[0].id, null)
}

output "regional_rules" {
  description = "Regional rules."
  value       = try([for k in google_compute_region_network_firewall_policy_rule.default : k.id], null)
}

output "regional_policy_name" {
  description = "Regional network firewall policy name"
  value       = try(google_compute_network_firewall_policy_rule.default[0].id, null)
}




