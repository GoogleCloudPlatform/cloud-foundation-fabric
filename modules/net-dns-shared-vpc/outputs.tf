output "teams_dns_networks" {
  description = "Networks for the DNS projects for application teams"
  value       = google_compute_network.dns_vpc_network[*]
} 