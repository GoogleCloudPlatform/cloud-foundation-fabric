output "external_address" {
  value = google_compute_instance.instance.network_interface.0.access_config.0.nat_ip
}

output "internal_address" {
  value = google_compute_instance.instance.network_interface.0.network_ip
}

output "name" {
  value = google_compute_instance.instance.name
}
