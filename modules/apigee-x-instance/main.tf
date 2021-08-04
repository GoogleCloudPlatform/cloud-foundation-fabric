resource "google_apigee_instance" "apigee_instance" {
  org_id             = var.apigee_org_id
  name               = var.name
  location           = var.region
  peering_cidr_range = "SLASH_${var.cidr_mask}"
  #disk_encryption_key_name = google_kms_crypto_key.apigee_key.id
}


resource "google_apigee_instance_attachment" "apigee_instance_attchment" {
  for_each     = toset(var.apigee_environments)
  instance_id  = google_apigee_instance.apigee_instance.id
  environment  = each.key
}
