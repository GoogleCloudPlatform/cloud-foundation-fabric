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
    touch blueprints/gke/patterns/autopilot-cluster/terraform.tfvars
    ```

2. Open <walkthrough-editor-open-file filePath="cloudshell_open/cloud-foundation-fabric/blueprints/gke/patterns/autopilot-cluster/terraform.tfvars">blueprints/gke/patterns/autopilot-cluster/terraform.tfvars</walkthrough-editor-open-file> file.

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
      cd blueprints/gke/patterns/autopilot-cluster/
      terraform init
    ```

5. Deploy GKE Autopilot cluster
    ```sh
    terraform apply
    ````

Once finished successfully (this can take up to 20 minutes) you should see following output at the end:
```terminal
tbd
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
    cat <<EOF > terraform.tfvars
    credentials_config = {
      fleet_host = "$(cd ../autopilot-cluster && terraform output fleet_host )"
    }
    EOF
    ```

You can also customize the sizing of MySQL instance by providing mysql_config (link to docs).

## Deploy
```sh
terraform apply
```

## Congratulations

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

You're all set!

**Don't forget to clean up after yourself**: If you created test projects, be sure to delete them to avoid unnecessary charges. Use `gcloud projects delete <PROJECT-ID>`.
