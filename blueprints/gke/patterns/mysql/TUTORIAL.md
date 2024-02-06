# Deploying MySQL highly available cluster on top of Google Kubernetes Engine
<walkthrough-tutorial-duration duration="40"></walkthrough-tutorial-duration>

## Let's get started!
This guide will show you how to deploy MySQL highly available cluster on top Google Kubernetes Engine.

During this guide you will deploy a new GKE cluster, MySQL database and you will connect to database to check its connectivity.

**Time to complete**: About TBC minutes
**Prerequisites**: A Cloud Billing account

Click the **Start** button to move to the next step.


## Prepare the infrastructure
```sh
touch blueprints/gke/jumpstart/jumpstart-0-infra/terraform.tfvars
```

Open <walkthrough-editor-open-file filePath="cloudshell_open/cloud-foundation-fabric/blueprints/gke/jumpstart/jumpstart-0-infra/terraform.tfvars">../jumpstart-0-infra/terraform.tfvars</walkthrough-editor-open-file> file and provide your project details:

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

```tfvars
project_id     = "<walkthrough-project-id/>"
cluster_name   = "cluster-00"
cluster_create = {}
vpc_create = {
    enable_cloud_nat = true
}
```

And run following command to create a cluster:
```sh
(cd ../jumpstart-0-infra && terraform apply -auto-approve)
```

Once finished successfully (this can take up to 20 minutes) you should see following output at the end:
```terminal
tbd
```

## Prepare configuration for MySQL deployment
To deploy MySQL you need to provide a few references to already created GKE cluster. The module used provides outputs
which helps to create those references:
```sh
cat <<EOF > terraform.tfvars
credentials_config = {
  fleet_host = "$(cd ../jumpstart-0-infra && terraform output ... )"
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