# Deploying a highly available MySQL cluster on top of Google Kubernetes Engine
<walkthrough-tutorial-duration duration="40"></walkthrough-tutorial-duration>

## Let's get started!
This guide will show you how to deploy MySQL highly available cluster on top Google Kubernetes Engine. The uses 3 MySQL instances behind MySQL-proxy which is responsible to route traffic to active instance.

During this guide you will deploy a new GKE cluster, MySQL database and you will connect to database to check its connectivity.

**Time to complete**: About 30 minutes

**Prerequisites**: A GCP Project with billing enabled

**Estimated cost**: $10/day

Click the **Start** button to move to the next step.


## Create or select a project
<walkthrough-project-setup billing="true"></walkthrough-project-setup>

## Install Terraform 1.7.4+ version
Install recent version of Terraform by executing following commands:

```sh
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

## Create GKE autopilot cluster
1. Create a new `terraform.tfvars` file
    ```sh
    touch autopilot-cluster/terraform.tfvars
    ```

2. Open <walkthrough-editor-open-file filePath="autopilot-cluster/terraform.tfvars">autopilot-cluster/terraform.tfvars</walkthrough-editor-open-file> file.

3. Paste the following content into the file and adapt for your needs if necessary
   ```hcl
   project_id     = "<walkthrough-project-id/>"
   cluster_name   = "gke-patterns-cluster"
   cluster_create = {
     deletion_protection = false
     labels = {
       pattern = "mysql"
     }
   }
   region = "europe-west4"
   vpc_create = {
     enable_cloud_nat = true
   }
   ```
MySQL cluster images are downloaded from Oracle repository, thus cluster network requires Internet connectivity. This is provided by provisioning Cloud NAT instance.

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
     "cluster" = "projects/wns-gke-cloudshell/locations/europe-west8/clusters/gke-patterns-cluster"
     "node_service_account" = "jump-0@<project-id>.gserviceaccount.com"
     "registry" = "europe-west8-docker.pkg.dev/<project-id>/jump-0"
     "router" = "<project-id>/europe-west8/default-nat/default"
     "subnet_id" = "projects/<project-id>/regions/europe-west8/subnetworks/jump-0-default"
     "vpc_id" = "projects/<project-id>/global/networks/jump-0"
   }
   credentials_config = {
     "fleet_host" = "https://connectgateway.googleapis.com/v1/projects/<project-number>/locations/global/gkeMemberships/gke-patterns-cluster"
   }
   fleet_host = "https://connectgateway.googleapis.com/v1/projects/<project-number>/locations/global/gkeMemberships/gke-patterns-cluster"
   get_credentials = {
     "direct" = "gcloud container clusters get-credentials gke-patterns-cluster --project <project-id> --location europe-west8"
     "fleet" = "gcloud container fleet memberships get-credentials gke-patterns-cluster --project <project-id>"
   }
   region = "europe-west4"
   ```

## Prepare configuration for MySQL deployment
To deploy MySQL you need to provide a few references to already created GKE cluster. The module used provides outputs
which helps to create those references.

1. Change directory to mysql
    ```sh
    cd ../mysql
    ```
2. Create a new `terraform.tfvars` for MySQL deployment
   ```sh
   touch terraform.tfvars
   ```

3. Open <walkthrough-editor-open-file filePath="mysql/terraform.tfvars">mysql/terraform.tfvars</walkthrough-editor-open-file> file.

4. Paste the following content into the file and adapt for your needs if necessary
   ```tfvars
   created_resources = {
     vpc_id    = "jump-0"
     subnet_id = "projects/<walkthrough-project-id/>/regions/europe-west4/subnetworks/jump-0-default"
   }
   credentials_config = {
     kubeconfig = {
       path = "~/.kube/config"
     }
   }
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
   }
   namespace  = "mysql-ha"
   project_id = "<walkthrough-project-id/>"
   region     = "europe-west4"  # use the same region as for autopilot-cluster
   ```

5. Get credentials for created cluster
   ```sh
   gcloud container fleet memberships get-credentials gke-patterns-cluster --project <walkthrough-project-id/>
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
   ```sh
   kubectl get statefulset -n mysql-ha mycluster -w
   ```
You should see following response, when all nodes are ready:
   ```terminal
   NAME        READY   AGE
   mycluster   0/3     118s
   mycluster   1/3     3m39s
   mycluster   2/3     3m54s
   mycluster   3/3     4m5s
   ```
   It takes 4-5 minutes time, as cluster needs to create new nodes to accommodate this workload. Once all nodes are ready, press ctrl-c to return to the command line.

## Check connectivity
1. Get password to MySQL user
   ```sh
   echo $(terraform output -raw mysql_password)
   ```

2. Login to bastion host:
   ```sh
   gcloud compute ssh --project <walkthrough-project-id/>  bastion
   ```

3. Install mysql-client:
   ```sh
   sudo apt update
   sudo apt install -y mariadb-client
   ```

4. Connect to database
   ```sh
   mysql --ssl -h 10.0.0.20 -P 6446 -u root -p
   ```
And paste copied password.

5. Create a sample table
```sh
use mysql
create table ha_test(id INT NOT NULL AUTO_INCREMENT, data varchar(64), PRIMARY KEY (id));
insert into ha_test(data) values('123');
select * from ha_test;
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
