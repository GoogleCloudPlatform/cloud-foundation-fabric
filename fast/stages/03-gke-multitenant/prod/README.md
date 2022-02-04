## IAM

- project+infra cluster admin

- cluster admins
  they have IAM bindings at proj level

- namespace admins / users
  cluster user? only IAM role to fetch GKE creds
everything else is in RBAC (second part of this stage)

- permissions to node service accounts
  - logging/monitoring
  - image registry

- custom role to only allow autoprovisioning of credentials

## Inputs from previous stages

- vpc host and subnets

## Network User role

- (optional) resman stage 01 creates SA, net stage 02 sets role on net project, dev --> dev, prod --> prod
- (always possible) subnet factory assigns role

## Resources

### Robot service accounts

- configured after prject activation (svpc roles, etc.)
  - gke host service agent
  - option for security admin
  - CMEK for disks

### Service accounts

- node service accounts (per nodepool?)
- config sync service account (start with a single one, +wl identity)
- backup for GKE

### Registry

- per env?
- deep dive on partitioning per team

### Clusters and nodepools

- n clusters
- no default nodepool (or default nodepool has taints -- infra nodepool)
- what can change between clusters?
  - stays the same
    - monitoring and logging config
    - autoprovisioning
    - private / public
    - workload identity
    - cloud dns
  - can change between clusters
    - dataplane v2
    - nodepools
    - binary auth
- nodepools per cluster

## Addresses for ILBs

## Filestore

- later

## RBAC


org
- GKE
- prod
- dev
- core

branch: gke-stage3

resman
GKE folder + env folders + gcs + sa (extra file to drop in stage 1)

[TF] supporting infra - stage 3 gke / infra (apply with SA from stage 1)
**single environment** (e.g. prod)
IAM for admins and users
projects for clusters
VPC wiring
logging
monitoring
container registries
source repos
workload identity config
Secrets (?)
clusters and nodepools and service accounts
managed prometheus?

[Manifests/etc.] multitenant cluster config - stage 3 gke / cluster config (apply/runs with credentials from infra part)
config sync
gatekeeper
team namespaces
network policies
in-cluster logging and monitoring


