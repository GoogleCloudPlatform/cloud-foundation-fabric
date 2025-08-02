context = {
  custom_roles = {
    storage_viewer = "organizations/366118655033/roles/storageViewer"
  }
  folder_ids = {
    default = "folders/221936889085"
  }
  iam_principals = {
    app0-devs       = "group:app0-devs@ludo.joonix.net"
    devops          = "group:gcp-devops@ludo.joonix.net"
    org-admins      = "group:gcp-organization-admins@ludo.joonix.net"
    security-admins = "group:gcp-security-admins@ludo.joonix.net"
    network-admins  = "group:gcp-network-admins@ludo.joonix.net"
  }
}
data_defaults = {
  parent           = "$folder_ids:default"
  storage_location = "eu"
}
data_overrides = {
  billing_account = "017479-47ADAB-670295"
  prefix          = "pf00"
}
factories_config = {
  folders  = "sample-data-1/folders"
  projects = "sample-data-1/projects"
}
