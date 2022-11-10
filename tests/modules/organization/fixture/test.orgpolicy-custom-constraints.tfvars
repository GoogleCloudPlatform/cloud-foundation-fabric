org_policy_custom_constraints = {
  "custom.gkeEnableAutoUpgrade" = {
    resource_types = ["container.googleapis.com/NodePool"]
    method_types   = ["CREATE"]
    condition      = "resource.management.autoUpgrade == true"
    action_type    = "ALLOW"
    display_name   = "Enable node auto-upgrade"
    description    = "All node pools must have node auto-upgrade enabled."
  },
  "custom.dataprocNoMoreThan10Workers" = {
    resource_types = ["dataproc.googleapis.com/Cluster"]
    method_types   = ["CREATE", "UPDATE"]
    condition      = "resource.config.workerConfig.numInstances + resource.config.secondaryWorkerConfig.numInstances > 10"
    action_type    = "DENY"
    display_name   = "Total number of worker instances cannot be larger than 10"
    description    = "Cluster cannot have more than 10 workers, including primary and secondary workers."
  }
}
