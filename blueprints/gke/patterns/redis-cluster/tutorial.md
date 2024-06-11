# Deploy a Redis cluster on GKE


## Objectives

This tutorial covers the following steps:

- Create a GKE cluster.
- Create a Redis Cluster on GKE.
- Confirm the redis is up and running.
- Confirm creation of the volumes for the stateful set.
- Confirm the Pod Disruption Budget (PDB).

Estimated time:
<walkthrough-tutorial-duration duration="30"></walkthrough-tutorial-duration>

To get started, click Start.

## select/create a project

<walkthrough-project-setup billing="true"></walkthrough-project-setup>

## Install Terraform 1.7.4+ version
Install recent version of Terraform by executing following commands:

```sh
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor --batch --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

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
cluster_name   = "gke-patterns-cluster"
cluster_create = {
  deletion_protection = false
  labels = {
    pattern = "redis-cluster"
  }
}
region         = "europe-west1"
vpc_create = { }
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
    gcloud container fleet memberships get-credentials gke-patterns-cluster --project "<walkthrough-project-name/>"
    ```

8. Check the nodes are ready.

    ```bash
    kubectl get pods -n kube-system
    ```

## Install Redis and create associated resources

1. Change to the ```patterns/redis-cluster``` directory.

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
   statefulset_config = {
      replicas = 8
      resource_requests = {
        cpu = "1"
        memory = "1.5Gi"
      }
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
    kubectl get pods -n redis
    ```

8. Check that the Redis volumes match the number of replicas

    ```bash
    kubectl get pv
    ```

8. Confirm the Pod Disruption Budget for redis guarantees at least 3 pods are up during a voluntary disruption

    ```bash
    kubectl describe pdb redis-pdb -n redis
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
