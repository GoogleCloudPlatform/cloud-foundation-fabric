prefix = "test"
workforce_identity_pools = {
  prefixed-pool = {
    display_name = "Prefixed pool."
    providers = {
      saml-test = {
        attribute_mapping_template = "azuread"
        identity_provider = {
          saml = {
            idp_metadata_xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
          }
        }
      }
    }
  }
  explicit-pool = {
    display_name = "Pool with explicit id."
    pool_id      = "explicit-pool-id"
  }
}
