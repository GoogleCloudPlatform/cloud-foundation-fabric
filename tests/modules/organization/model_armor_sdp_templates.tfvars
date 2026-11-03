model_armor_floor_setting = {
  enforce                  = false
  multi_language_detection = true
  filters = {
    rai = null
    sdp = {
      inspect_template    = "projects/my-project/locations/global/inspectTemplates/inspect"
      deidentify_template = "projects/my-project/locations/global/deidentifyTemplates/deidentify"
    }
  }
}
