context = {
  locations = {
    my_region = "europe-west1"
  }
  networks = {
    my_network = "projects/my-project/global/networks/my-network"
  }
  project_ids = {
    my_project = "my-project"
  }
  routers = {
    my_router = "my-router"
  }
}

dedicated_interconnect_config = {
  bandwidth    = "BPS_100G"
  bgp_range    = "169.254.1.0/29"
  bgp_priority = 100
  interconnect = "projects/my-project/global/interconnects/my-interconnect"
  vlan_tag     = 100
}

description = "test attachment"
name        = "test-attachment"
peer_asn    = "65534"

network    = "$networks:my_network"
project_id = "$project_ids:my_project"
region     = "$locations:my_region"

router_config = {
  create = false
  name   = "$routers:my_router"
}
