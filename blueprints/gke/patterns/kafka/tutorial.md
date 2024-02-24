# Deploy Apache Kafka to GKE using Strimzi

The guide shows you how to use the Strimzi operator to deploy Apache Kafka clusters ok GKE.

## Objectives

This tutorial covers the following steps:

- Create a GKE cluster.
- Deploy and configure the Strimzi operator
- Configure Apache Kafka using the Strimzi operator

Estimated time:
<walkthrough-tutorial-duration duration="30"></walkthrough-tutorial-duration>

To get started, click Start.

## select/create a project

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

## Create the Autopilot GKE cluster

1. Change to the ```autopilot-cluster``` directory.

    ```bash
    cd autopilot-cluster 
    ```

2. Create a new file ```terraform.tfvars``` in that directory.

    ```bash
    touch terraform.tfvars
    ```

3. Open the <walkthrough-editor-open-file filePath="autopilot-cluster/terraform.tfvars">file</walkthrough-editor-open-file> for editing.

4. Paste the following content in the file and update any value as needed.

```hcl
project_id     = "<walkthrough-project-name/>"
cluster_name   = "cluster"
cluster_create = {
  deletion_protection = false
}
region         = "europe-west1"
vpc_create = {
  enable_cloud_nat = true
}
```

5. Initialize the terraform configuration.

    ```bash
    terraform init
    ```

6. Apply the terraform configuration.

    ```bash
    terraform apply
    ```

7. Fetch the cluster credentials.

    ```bash
    gcloud container fleet memberships get-credentials cluster --project "<walkthrough-project-name/>"
    ```

8. Check the nodes are ready.

    ```bash
    kubectl get pods -n kube-system
    ```

## Install the Kafka Strimzi operator and create associated resources

1. Change to the ```patterns/batch``` directory.

    ```bash
    cd ../redis-cluster
    ```

2. Create a new file ```terraform.tfvars``` in that directory.

    ```bash
    touch terraform.tfvars
    ```

3. Open the <walkthrough-editor-open-file filePath="batch/terraform.tfvars">file</walkthrough-editor-open-file> for editing.

4. Paste the following content in the file.

    ```hcl
    credentials_config = {
      kubeconfig = {
        path = "~/.kube/config"
      }
    }
    kafka_config = {
      volume_claim_size = "15Gi"
      replicas          = 4
    }
    zookeeper_config = {
      volume_claim_size = "15Gi"
    }
    ```

5. Initialize the terraform configuration.

    ```bash
    terraform init
    ```

6. Apply the terraform configuration.

    ```bash
    terraform apply
    ```

7. Check that the Redis pods are ready

    ```bash
    kubectl get pods -n kafka
    ```

8. Check that the Redis volumes match the number of replicas

    ```bash
    kubectl get pv
    ```

8. Confirm the Kafka object is running

    ```bash
    kubectl get kafka -n kafka
    ```

## Destroy resources (optional)
1. Change to the ```patterns/autopilot-cluster``` directory.

    ```bash
    cd ../autopilot-cluster
    ```

2. Destroy the cluster with the following command.

    ```bash
    terraform destroy
    ```

## Congratulations

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

You’re all set!
