project_id   = "myproject"
cluster_id   = "alloydb-cluster-all"
location     = "europe-west2"
labels       = {}
display_name = "alloydb-cluster-all"
initial_user = {
  user     = "alloydb-cluster-full",
  password = "alloydb-cluster-password"
}
network_self_link = "projects/myproject/global/networks/default"

automated_backup_policy = null

primary_instance_config = {
  instance_id       = "primary-instance-1",
  instance_type     = "PRIMARY",
  machine_cpu_count = 2,
  database_flags    = {},
  display_name      = "alloydb-primary-instance"
}


read_pool_instance = [
  {
    instance_id       = "read-instance-1",
    display_name      = "read-instancename-1",
    instance_type     = "READ_POOL",
    node_count        = 1,
    database_flags    = {},
    machine_cpu_count = 1
  },
  {
    instance_id       = "read-instance-2",
    display_name      = "read-instancename-2",
    instance_type     = "READ_POOL",
    node_count        = 1,
    database_flags    = {},
    machine_cpu_count = 1
  }
]
