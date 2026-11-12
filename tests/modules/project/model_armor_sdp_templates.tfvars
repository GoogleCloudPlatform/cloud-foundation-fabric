model_armor_floor_setting = {
  enforce = false
  filters = {
    rai = null
    sdp = {
      inspect_template    = "projects/my-project/locations/global/inspectTemplates/inspect"
      deidentify_template = "projects/my-project/locations/global/deidentifyTemplates/deidentify"
    }
  }
  integrated_services = {
    google_mcp_server = {
      mode = "inspect_and_block"
    }
  }
}
