output "name" {
  description = "The name of the VLAN attachment created."
  #value       = google_compute_interconnect_attachment.encrypted[0].name
  value = local.ipsec_enabled ? google_compute_interconnect_attachment.encrypted[0].name : google_compute_interconnect_attachment.unencrypted[0].name
}

output "id" {
  description = "The id of the VLAN attachment created."
  #value       = google_compute_interconnect_attachment.encrypted[0].id
  value = local.ipsec_enabled ? google_compute_interconnect_attachment.encrypted[0].id : google_compute_interconnect_attachment.unencrypted[0].id
}

output "router" {
  description = "Router resource (only if auto-created)."
  value       = local.ipsec_enabled ? one(google_compute_router.encrypted[*]) : one(google_compute_router.unencrypted[*])
}

output "router_name" {
  description = "Router name."
  value       = local.router
}
