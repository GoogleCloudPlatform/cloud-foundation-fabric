resource "google_notebooks_runtime" "runtime" {
  for_each = var.notebooks
  name     = each.key

  project  = module.project.project_id
  location = var.notebooks[each.key].region
  access_config {
    access_type   = "SINGLE_USER"
    runtime_owner = var.notebooks[each.key].owner
  }
  software_config {
    enable_health_monitoring = true
    idle_shutdown            = var.notebooks[each.key].idle_shutdown_timeout
    idle_shutdown_timeout    = 1800
  }
  virtual_machine {
    virtual_machine_config {
      machine_type = "n1-standard-4"
      network      = "projects/${module.project.project_id}/global/networks/${module.vpc-local[0].name}"
      #TODO: make subnet variable
      subnet           = "projects/${module.project.project_id}/regions/${var.notebooks[each.key].region}/subnetworks/${var.notebooks[each.key].subnet}"
      internal_ip_only = var.notebooks[each.key].internal_ip_only
      #reserved_ip_range = "vertex"

      metadata = {
        notebook-disable-nbconvert = "false"
        notebook-disable-downloads = "false"
        notebook-disable-terminal  = "false"
        #notebook-disable-root      = "true"
        #notebook-upgrade-schedule  = "48 4 * * MON"
      }
      data_disk {
        initialize_params {
          disk_size_gb = "100"
          disk_type    = "PD_STANDARD"
        }
      }
    }
  }
}

