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

# test 4  - create cluster and vpc, existing project
# project_id     = "tf-playground-svpc-gke-fleet"
# cluster_name   = "test-01"
# create_cluster = {}
# create_vpc     = {}

# test 5 - create cluster project, no shared vpc ---> implied vpc
# project_id     = "tf-playground-svpc-gke-j0"
# cluster_name   = "test-00"
# create_cluster = {}
# create_project = {
#   billing_account = "017479-47ADAB-670295"
#   parent          = "folders/210938489642"
# }

# test 6 - create cluster project, shared vpc no cluster net ---> fail check
# project_id     = "tf-playground-svpc-gke-j1"
# cluster_name   = "test-00"
# create_cluster = {}
# create_project = {
#   billing_account = "017479-47ADAB-670295"
#   parent          = "folders/210938489642"
#   shared_vpc_host = "ldj-prod-net-landing-0"
# }

# test 7 - create cluster project, shared vpc cluster net ---> pass check
project_id   = "tf-playground-svpc-gke-j1"
cluster_name = "test-00"
create_cluster = {
  vpc = {
    id        = "projects/ldj-dev-net-spoke-0/global/networks/dev-spoke-0"
    subnet_id = "projects/ldj-dev-net-spoke-0/regions/europe-west8/subnetworks/gke"
  }
}
create_project = {
  billing_account = "017479-47ADAB-670295"
  parent          = "folders/210938489642"
  shared_vpc_host = "ldj-dev-net-spoke-0"
}
