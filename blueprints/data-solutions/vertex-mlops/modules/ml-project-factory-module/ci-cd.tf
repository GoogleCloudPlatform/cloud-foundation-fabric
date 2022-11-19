
resource "google_iam_workload_identity_pool" "github_pool" {
  count                     = var.workload_identity == null ? 0 : 1
  provider                  = google-beta
  project                   = module.project.project_id
  workload_identity_pool_id = "gh-pool"
  display_name              = "Github Actions Identity Pool"
  description               = "Identity pool for Github Actions"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  count                              = var.workload_identity == null ? 0 : 1
  provider                           = google-beta
  project                            = module.project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "gh-provider"
  display_name                       = "Github Actions provider"
  description                        = "OIDC provider for Github Actions"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

module "service-account-gh" {
  count                  = var.workload_identity == null ? 0 : 1
  service_account_create = false
  source                 = "../../../../../modules/iam-service-account"
  project_id             = module.project.project_id
  name                   = module.service-accounts["sa-github"].name
  generate_key           = false

  # authoritative roles granted *on* the service accounts to other identities
  iam = {
    "roles/iam.workloadIdentityUser" = ["principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool[0].name}/${var.workload_identity.identity_pool_claims}"]
  }
}

module "artifact_registry" {
  for_each   = var.artifact_registry
  source     = "../../../../../modules/artifact-registry"
  id         = each.key
  project_id = module.project.project_id
  location   = each.value.region
  format     = each.value.format
  #  iam = {
  #    "roles/artifactregistry.admin" = ["group:cicd@example.com"]
  #  }
}