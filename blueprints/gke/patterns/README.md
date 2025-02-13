# GKE Patterns

This directory includes several blueprints related to Google Kubernetes Engine (GKE), following Google recommendations and best practices. The blueprints in this directory split the deployment process into two stages: an initial infrastructure stage that provisions the cluster, and additional workload stages that deploy specific types of applications/workloads.

As a design rule, all the blueprints in this directory provide sensible defaults for most variables while still providing an enterprise-grade deployment with secure defaults and the ability to use existing resources that are typically found in an enterprise-grade environment.
