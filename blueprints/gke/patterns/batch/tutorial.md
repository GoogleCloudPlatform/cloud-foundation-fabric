# Deploy a batch system using Kueue

This tutorial shows you how to deploy a batch system using Kueue to perform Job queueing on Google Kubernetes Engine (GKE) using Terraform.

Jobs are applications that run to completion, such as machine learning, rendering, simulation, analytics, CI/CD, and similar workloads.

Kueue is a Cloud Native Job scheduler that works with the default Kubernetes scheduler, the Job controller, and the cluster autoscaler to provide an end-to-end batch system. Kueue implements Job queueing, deciding when Jobs should wait and when they should start, based on quotas and a hierarchy for sharing resources fairly among teams.

Kueue has the following characteristics:

* It is optimized for cloud architectures, where resources are heterogeneous, interchangeable, and scalable.
* It provides a set of APIs to manage elastic quotas and manage Job queueing.
* It does not re-implement existing functionality such as autoscaling, pod scheduling, or Job lifecycle management.
* Kueue has built-in support for the Kubernetesbatch/v1.Job API.
* It can integrate with other job APIs.
* Kueue refers to jobs defined with any API as Workloads, to avoid the confusion with the specific Kubernetes Job API.

When working with Kueue there are a few concepts that one needs to be familiar with:

* ResourceFlavour

    An object that you can define to describe what resources are available in a cluster. Typically, it is associated with the characteristics of a group of Nodes: availability, pricing, architecture, models, etc.

* ClusterQueue

    A cluster-scoped resource that governs a pool of resources, defining usage limits and fair sharing rules.

* LocalQueue

    A namespaced resource that groups closely related workloads belonging to a single tenant.

* Workload

    An application that will run to completion. It is the unit of admission in Kueue. Sometimes referred to as job

Kueue refers to jobs defined with any API as Workloads, to avoid the confusion with the specific Kubernetes Job API.

## Objectives

This tutorial is for cluster operators and other users that want to implement a batch system on Kubernetes. In this tutorial, you set up a shared cluster for two tenant teams. Each team has their own namespace where they create Jobs and share the same global resources that are controlled with the corresponding quotas.

In this tutorial we will be doing the following using Terraform code available in a git repository:

1. Create a GKE cluster.
2. Create a namespace for Kueue (kueue-system).
3. Create a namespace for each team running batch jobs in the cluster (team-a, team-b).
4. Install Kueue in the namespace created for it.
5. Create the ResourceFlavor.
6. Create the ClusterQueue.
7. Create a LocalQueue for each of the teams in the corresponding namespace.
8. Create for each of teams a manifest for a sample job associated with the corresponding LocalQueue.

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
    pattern = "batch"
  }
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
    gcloud container fleet memberships get-credentials gke-patterns-cluster --project "<walkthrough-project-name/>"
    ```

8. Check the nodes are ready.

    ```bash
    kubectl get pods -n kube-system
    ```

## Install Kueue and create associated resources

1. Change to the ```patterns/batch``` directory.

    ```bash
    cd ../batch
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
    ```

5. Initialize the terraform configuration.

    ```bash
    terraform init
    ```

6. Apply the terraform configuration.

    ```bash
    terraform apply
    ```

7. Check that the Kueue pods are ready (Use CTRL+C to exit watching)

    ```bash
    kubectl get pods -n kueue-system -w
    ```

8. Check the status of the ClusterQueue

    ```bash
    kubectl get clusterqueue cluster-queue -o wide -w
    ```

9. Check the status of the LocalQueue for the teams

    ```bash
    kubectl get localqueue -n team-a local-queue -o wide -w
    ```

    ```bash
    kubectl get localqueue -n team-b local-queue -o wide -w
    ```

## Run jobs in the cluster

1.  Create Jobs for namespace team-a and team-b every 10 seconds associated with the corresponding LocalQueue:

    ```bash
    ./create_jobs.sh job-team-a.yaml job-team-b.yaml 10
    ```

    Hit Ctrl-C when you want to stop the creation of jobs

2. Observe the workloads being queued up, admitted in the ClusterQueue, and nodes being brought up with GKE Autopilot.

    ```bash
    kubectl -n team-a get workloads
    ```

3. Copy a Job name from the previous step and observe the admission status and events for a Job through the W    Workloads API:

    ```bash
    kubectl -n team-a describe workload JOB_NAME
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
