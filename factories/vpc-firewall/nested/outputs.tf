output "vpc-firewall-rules" {
  description = "Generated VPC Firewall Rules"
  value       = merge(google_compute_firewall.rules-allow, google_compute_firewall.rules-deny)
}
