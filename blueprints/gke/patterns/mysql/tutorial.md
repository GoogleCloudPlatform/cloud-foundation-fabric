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
   cluster_create = {
     deletion_protection = false
   }
   region = "europe-west4"
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

1. Pass outputs from autopilot-cluster module to the mysql module
This passes information about cluster endpoint network, subnetwork and region, so it is not necessary to configure that manually.
   ```sh
   terraform output -json > ../mysql/terraform.tfvars.json
   ```

2. Change directory to mysql
    ```sh
    cd ../mysql
    ```
3. Create a new `terraform.tfvars` for MySQL deployment
   ```sh
   touch terraform.tfvars
   ```

4. Open <walkthrough-editor-open-file filePath="mysql/terraform.tfvars">mysql/terraform.tfvars</walkthrough-editor-open-file> file.

5. Paste the following content into the file and adapt for your needs if necessary

   ```tfvars
   mysql_config = {
      ip_address       = "10.0.0.20"
      # db_cpu           = "500m"
      # db_database_size = "10Gi"
      # db_memory        = "1Gi"
      # db_replicas      = 3
      # router_replicas  = 2 # cannot be higher than number of the zones in region
      # router_cpu       = "500m"
      # router_memory    = "2Gi"
      # version          = "8.0.34"
   })
   namespace  = "mysql-ha"
   project_id = "<walkthrough-project-id/>"
   ```

6. Get credentials for created cluster
   ```sh
   gcloud container fleet memberships get-credentials cluster-00 --project <walkthrough-project-id/>
   ```

## Deploy
1. Initialize terraform
   ```sh
   terraform init
    ```

2. Deploy MySQL
    ```sh
    terraform apply
    ````

3. Wait until deployment is ready
It takes some time, as cluster needs to create new nodes to accomodate this workload

## Check connectivity
1. Get password to login to server
   ```sh
   kubctl secret list
   ```

2. Login to bastion host:
   ```sh
   gcloud compute ssh --project <walkthrough-project-id/>  bastion
   ```

3. Install mysql-client:
```sh
apt install mysql-client
```

4. Connect to database
```sh
mysql -h 10.0.0.20 -u root
```

## Congratulations

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

You're all set!

**Don't forget to clean up after yourself**: If you created test projects, be sure to delete them to avoid unnecessary charges. Use `gcloud projects delete <PROJECT-ID>`.
To remove MySQL resources:
```sh
terraform destroy
```

And then remove the cluster:
```sh
cd ../autopilot-cluster
terraform destroy
```

Self-link: https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git&cloudshell_tutorial=mysql/tutorial.md&cloudshell_git_branch=gke-blueprints/0-redis&cloudshell_workspace=blueprints/gke/patterns&show=ide%2Cterminal
