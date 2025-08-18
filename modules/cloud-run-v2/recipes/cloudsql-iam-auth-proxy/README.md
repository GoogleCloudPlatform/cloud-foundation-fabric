Cloud Run provides shorthand to connect to Cloud SQL database, but that requires connecting using password. In this recipe connection is authorized using IAM

```hcl
# create service account for Cloud Run service
module "run-sa" {
  source     = "./fabric/modules/iam-service-account"
  project_id = var.project_id
  name       = "db-run"
  iam_project_roles = {
    (var.project_id) = [
      "roles/storage.objectViewer",
      "roles/logging.logWriter",
      "roles/cloudsql.client",
      "roles/cloudsql.instanceUser"
    ]
  }
}

# Create MySQL database
module "db" {
  source     = "./fabric/modules/cloudsql-instance"
  project_id = var.project_id
  network_config = {
    connectivity = {
      psa_config = {
        private_network = var.vpc.self_link
      }
    }
  }
  name             = "db"
  region           = var.region
  database_version = "MYSQL_8_4"
  tier             = "db-g1-small"

  flags = {
    cloudsql_iam_authentication    = "on"
    disconnect_on_expired_password = "on"
  }

  databases = [
    "test"
  ]

  users = {
    # IAM Service Account
    (module.run-sa.email) = {
      type = "CLOUD_IAM_SERVICE_ACCOUNT"
    }
  }
  gcp_deletion_protection       = false
  terraform_deletion_protection = false
}

module "database_run" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = "db-test"
  region     = var.region
  containers = {
    sqlproxy = {
      image = "docker.io/phpmyadmin"
      ports = {
        "" = {
          container_port = 8080
          name           = "http1"
        }
      }
      env = {
        APACHE_PORT = "8080"
        PMA_SOCKET  = "/cloudsql/${module.db.connection_name}"
        PMA_USER    = split("@", module.run-sa.email)[0]
      }
      volume_mounts = {
        custom_cloudsql = "/cloudsql"
      }
    }
    authproxy = {
      name  = "cloudsql"
      image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.18.0"
      args = [
        "--auto-iam-authn",
        "--private-ip",
        "--unix-socket=/cloudsql",
        module.db.connection_name
      ]
      ports = {}
      volume_mounts = {
        custom_cloudsql = "/cloudsql"
      }
    }
  }
  service_account     = module.run-sa.email
  deletion_protection = false
  volumes = {
    custom_cloudsql = {
      empty_dir_size = "128k"
    }
  }
}
# tftest inventory=recipe-cloudsql-iam-auth-proxy.yaml e2e
```
