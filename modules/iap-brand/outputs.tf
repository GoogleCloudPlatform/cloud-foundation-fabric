output "client_id" {
  value = local.create_client ? google_iap_client.client[0].client_id : null
}

output "client_secret" {
  value = local.create_client ? google_iap_client.client[0].secret : null
}