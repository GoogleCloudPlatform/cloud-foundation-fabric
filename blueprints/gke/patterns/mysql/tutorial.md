# Deploying MySQL highly available cluster on top of Google Kubernetes EngineC
<walkthrough-tutorial-duration duration="40"></walkthrough-tutorial-duration>

## Let's get started!
This guide will show you how to deploy MySQL highly available cluster on top Google Kubernetes Engine. The uses
3 MySQL instances behind MySQL-proxy which is responsible to route traffic to active instance.

During this guide you will deploy a new GKE cluster, MySQL database and you will connect to database to check its connectivity.

**Time to complete**: About TBC minutes

**Prerequisites**: A Cloud Billing account

Click the **Start** button to move to the next step.


## Create or select a project

<walkthrough-project-setup billing="true"></walkthrough-project-setup>


## Create GKE autopilot cluster
1. Create a new `terraform.tfvars` file
    ```sh
    touch autopilot-cluster/terraform.tfvars
    ```

2. Open <walkthrough-editor-open-file filePath="autopilot-cluster/terraform.tfvars">autopilot-cluster/terraform.tfvars</walkthrough-editor-open-file> file.

3. Paste the following content into the file and adapt for your needs if necessary

    ```tfvars
    project_id     = "<walkthrough-project-id/>"
    cluster_name   = "cluster-00"
    cluster_create = {}
    vpc_create = {
        enable_cloud_nat = true
    }
    ```

4. Initialize terraform

    ```sh
      cd autopilot-cluster/
      terraform init
    ```

5. Deploy GKE Autopilot cluster
    ```sh
    terraform apply
    ````

Once finished successfully (this should take around 10 minutes) you should see following output at the end:
```terminal
Apply complete! Resources: 26 added, 0 changed, 0 destroyed.

Outputs:

created_resources = {
  "cloud_nat" = "projects/wns-gke-cloudshell/regions/europe-west8/routers/default-nat"
  "cluster" = "projects/wns-gke-cloudshell/locations/europe-west8/clusters/cluster-00"
  "node_service_account" = "jump-0@<project-id>.gserviceaccount.com"
  "registry" = "europe-west8-docker.pkg.dev/<project-id>/jump-0"
  "router" = "<project-id>/europe-west8/default-nat/default"
  "subnet_id" = "projects/<project-id>/regions/europe-west8/subnetworks/jump-0-default"
  "vpc_id" = "projects/<project-id>/global/networks/jump-0"
}
fleet_host = "https://connectgateway.googleapis.com/v1/projects/<project-number>/locations/global/gkeMemberships/cluster-00"
get_credentials = {
  "direct" = "gcloud container clusters get-credentials cluster-00 --project <project-id> --location europe-west8"
  "fleet" = "gcloud container fleet memberships get-credentials cluster-00 --project <project-id>"
}

```

## Prepare configuration for MySQL deployment
To deploy MySQL you need to provide a few references to already created GKE cluster. The module used provides outputs
which helps to create those references.

1. Change directory to mysql
    ```sh
    cd ../mysql
    ```
2. Create `terraform.tfvars` referencing GKE Autopilot cluster
    ```sh
    echo "credentials_config = {" > terraform.tfvars
    echo "fleet_host = $(cd ../autopilot-cluster && terraform output fleet_host )"  >> terraform.tfvars
    echo "}" >> terraform.tfvars
    ```

You can also customize the sizing of MySQL instance by providing mysql_config (link to docs).

## Deploy
1. Initialize terraform
   ```sh
   terraform init
    ```

2. Deploy MySQL
    ```sh
    terraform apply
    ````

## Congratulations

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

You're all set!

**Don't forget to clean up after yourself**: If you created test projects, be sure to delete them to avoid unnecessary charges. Use `gcloud projects delete <PROJECT-ID>`.


Self-link: https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git&cloudshell_tutorial=mysql/tutorial.md&cloudshell_git_branch=gke-blueprints/0-redis&cloudshell_workspace=blueprints/gke/patterns&show=ide%2Cterminal
