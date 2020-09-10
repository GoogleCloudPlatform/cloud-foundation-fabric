output "name" {
  value      = local.name
  depends_on = [google_compute_global_address.address, google_compute_managed_ssl_certificate.cert]
}