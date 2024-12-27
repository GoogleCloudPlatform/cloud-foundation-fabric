moved {
  from = module.dev-sec-kms["europe"]
  to   = module.kms["dev-europe"]
}
moved {
  from = module.dev-sec-kms["europe-west1"]
  to   = module.kms["dev-europe-west1"]
}
moved {
  from = module.dev-sec-kms["europe-west3"]
  to   = module.kms["dev-europe-west3"]
}
moved {
  from = module.dev-sec-kms["global"]
  to   = module.kms["dev-global"]
}
moved {
  from = module.dev-sec-project
  to   = module.project["dev"]

}

moved {
  from = module.prod-sec-kms["europe"]
  to   = module.kms["prod-europe"]
}
moved {
  from = module.prod-sec-kms["europe-west1"]
  to   = module.kms["prod-europe-west1"]
}
moved {
  from = module.prod-sec-kms["europe-west3"]
  to   = module.kms["prod-europe-west3"]
}
moved {
  from = module.prod-sec-kms["global"]
  to   = module.kms["prod-global"]
}
moved {
  from = module.prod-sec-project
  to   = module.project["prod"]
}
