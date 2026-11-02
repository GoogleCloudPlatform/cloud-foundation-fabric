workforce_identity_pools = {
  "test-pool" = {
    display_name = "Test Pool"
    description  = "Workforce pool for testing."
    providers = {
      oidc-full = {
        attribute_mapping = {
          "google.subject" = "assertion.sub"
        }
        identity_provider = {
          oidc = {
            issuer_uri = "https://sts.windows.net/abcd01234/"
            client_id  = "https://analysis.windows.net/powerbi/connector/GoogleBigQuery"
            client_secret = {
              path       = "./wfif-secret/client-secret.txt"
              wo_version = 1
            }
            web_sso_config = {
              response_type             = "CODE"
              assertion_claims_behavior = "MERGE_USER_INFO_OVER_ID_TOKEN_CLAIMS"
            }
          }
        }
      }
    }
  }
}
