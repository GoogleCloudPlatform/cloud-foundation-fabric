moved {
  from = module.vpc-sc[0].google_access_context_manager_service_perimeter.regular["default"]
  to   = module.vpc-sc.google_access_context_manager_service_perimeter.regular["default"]
}

moved {
  from = module.vpc-sc[0].google_access_context_manager_access_level.basic["geo"]
  to   = module.vpc-sc.google_access_context_manager_access_level.basic["geo"]
}

moved {
  from = module.vpc-sc[0].google_access_context_manager_access_policy.default[0]
  to   = module.vpc-sc.google_access_context_manager_access_policy.default[0]
}
