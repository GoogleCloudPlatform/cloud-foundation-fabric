# Deploy a batch system using Kueue

This tutorial shows you how to deploy a batch system using Kueue to perform Job queueing on Google Kubernetes Engine (GKE) using Terraform. 

## Background

Jobs are applications that run to completion, such as machine learning, rendering, simulation, analytics, CI/CD, and similar workloads.

Kueue is a Cloud Native Job scheduler that works with the default Kubernetes scheduler, the Job controller, and the cluster autoscaler to provide an end-to-end batch system. Kueue implements Job queueing, deciding when Jobs should wait and when they should start, based on quotas and a hierarchy for sharing resources fairly among teams.

Kueue has the following characteristics:

* It is optimized for cloud architectures, where resources are heterogeneous, interchangeable, and scalable.
* It provides a set of APIs to manage elastic quotas and manage Job queueing.
* It does not re-implement existing functionality such as autoscaling, pod scheduling, or Job lifecycle management.
* Kueue has built-in support for the Kubernetesbatch/v1.Job API.
* It can integrate with other job APIs.
* Kueue refers to jobs defined with any API as Workloads, to avoid the confusion with the specific Kubernetes Job API.

Kueue refers to jobs defined with any API as Workloads, to avoid the confusion with the specific Kubernetes Job API.

## Objectives

This tutorial is for cluster operators and other users that want to implement a batch system on Kubernetes. In this tutorial, you set up a shared cluster for two tenant teams. Each team has their own namespace where they create Jobs and share the same global resources that are controlled with the corresponding quotas.

In this tutorial we will be doing the following using Terraform:

1. Create a GKE cluster
2. Install Kueue in the cluster
2. Create the ResourceFlavor
3. Create the ClusterQueue
4. Create the LocalQueue

