context = {
  networks = {
    local = "projects/my-project/global/networks/local-vpc"
    peer  = "projects/peer-project/global/networks/peer-vpc"
  }
}

local_network = "$networks:local"
peer_network  = "$networks:peer"
