resource "google_project_iam_binding" "bindings" {
  project  = var.project_id
  role     = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members  = ["serviceAccount:${var.service_identities.secret_identity}"]
}

resource "google_kms_key_ring" "keyring_1" {
  name       = "keyring-1"
  project    = var.project_id
  location   = var.region_1
}

resource "google_kms_crypto_key" "key_1" {
  name            = "crypto-key-example-1"
  key_ring        = google_kms_key_ring.keyring_1.id
  rotation_period = "100000s"
  depends_on = [ google_project_iam_binding.bindings ]
}

resource "google_kms_key_ring" "keyring_gl" {
  name       = "keyring-gl"
  project    = var.project_id
  location   = "global"
}

resource "google_kms_crypto_key" "key_gl" {
  name            = "crypto-key-example-gl"
  key_ring        = google_kms_key_ring.keyring_gl.id
  rotation_period = "100000s"
  depends_on = [ google_project_iam_binding.bindings ]
}
