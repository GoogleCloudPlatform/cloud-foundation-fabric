When deploying Cloud Run, and using tags such as `latest`, terraform will not redeploy image after container is built. By using `google_artifact_registry_docker_image` data resource you can force update of the Cloud Run, each time container is rebuild.


```hcl
module "docker_artifact_registry" {
  source     = "./fabric/modules/artifact-registry"
  project_id = var.project_id
  format     = { docker = { standard = {} } }
  location   = var.region
  name       = "docker-registry"
}

data "google_artifact_registry_docker_image" "this" {
  project       = var.project_id
  image_name    = "image-name"
  location      = var.region
  repository_id = module.docker_artifact_registry.repository.repository_id
}

module "hello" {
  source     = "./fabric/modules/cloud-run-v2"
  project_id = var.project_id
  name       = "hello"
  region     = var.region
  containers = {
    hello = {
      image = data.google_artifact_registry_docker_image.this.self_link # self link returns image URI with hash
    }
  }
}

# tftest skip
```
