module "project" {
  source         = "./project"
  name           = "lcaggioni-sandbox"
  project_create = false
  service_encryption_key_ids = {
    composer = [
      "projects/kms-central-prj/locations/europe-west3/keyRings/my-keyring/cryptoKeys/europe3-gce",
    ]
  }
}
