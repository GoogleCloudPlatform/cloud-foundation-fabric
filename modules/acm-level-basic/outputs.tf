output "name" {
  value = local.policy != null ? google_access_context_manager_access_level.level[0].name : null
}
