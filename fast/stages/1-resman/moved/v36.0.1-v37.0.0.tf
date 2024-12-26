moved {
  from = module.net-folder-dev[0]
  to   = module.net-folder-envs["dev"]
}

moved {
  from = module.net-folder-prod[0]
  to   = module.net-folder-envs["prod"]
}

moved {
  from = module.sec-folder-dev[0]
  to   = module.sec-folder-envs["dev"]
}

moved {
  from = module.sec-folder-prod[0]
  to   = module.sec-folder-envs["prod"]
}
