locals {
  projects_bigquery_datasets = flatten([
    for k, v in local.projects_input : [
      for name, opts in lookup(v, "datasets", {}) : {
        project_key   = k
        project_name  = v.name
        name          = name
        dataset_id    = lookup(opts, "dataset_id", "")
        friendly_name = lookup(opts, "friendly_name", null)
        location      = lookup(opts, "location", null)
      }
    ]
  ])
}

module "bigquery-datasets" {
  source = "../bigquery-dataset"
  for_each = {
    for k in local.projects_bigquery_datasets : "${k.project_key}/${k.name}" => k
  }
  project_id    = module.projects[each.value.project_key].project_id
  id            = each.value.dataset_id
  friendly_name = each.value.friendly_name
  location = coalesce(
    local.data_defaults.overrides.bigquery_location,
    lookup(each.value, "location", null),
    local.data_defaults.defaults.bigquery_location
  )
}
