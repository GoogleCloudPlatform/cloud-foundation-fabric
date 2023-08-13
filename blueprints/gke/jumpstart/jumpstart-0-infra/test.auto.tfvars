# test 1 - existing cluster
# project_id = "tf-playground-svpc-gke-fleet"
# cluster_name = "test-00"

# test 2 - create cluster, existing project and vpc
# project_id   = "tf-playground-svpc-gke-fleet"
# cluster_name = "test-01"
# create_cluster = {
#   vpc = {
#     id        = "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
#     subnet_id = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke"
#   }
# }

# test 3 - create cluster, existing project default network
# project_id     = "tf-playground-svpc-gke-fleet"
# cluster_name   = "test-01"
# create_cluster = {}

# test  - create cluster and vpc, existing project
project_id     = "tf-playground-svpc-gke-fleet"
cluster_name   = "test-01"
create_cluster = {}
create_vpc     = {}
