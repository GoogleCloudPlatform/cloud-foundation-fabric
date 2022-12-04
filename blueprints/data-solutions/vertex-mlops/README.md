# MLOps with Vertex AI - Infra setup

## Introduction
This example implements the infrastructure required to deploy an end-to-end [MLOps process](https://services.google.com/fh/files/misc/practitioners_guide_to_mlops_whitepaper.pdf) using [Vertex AI](https://cloud.google.com/vertex-ai) platform.


##  GCP resources
A terraform script is provided to setup all the required resources:

- GCP Project factory to host all the resources
- Per project VPC network and a subnet to be used by Vertex and Dataflow
- Firewall rule to allow the internal subnet communication required by Dataflow
- Cloud NAT, required to reach the internet from the different computing resources (Vertex and Dataflow)
- Service account with the minimum permissions required by Dataproc
- GCS bucket to host Vertex and Cloud Build Artifacts.
- Big Query Dataset to store the training data

![MLOps projects organization](./images/mlops_projects.png "MLOps projects organization")

## Pre-requirements

### User groups

User groups provide a stable frame of reference that allows decoupling the final set of permissions from the stage where entities and resources are created, and their IAM bindings defined.

We use three groups to control access to resources:

- *Data Scientits* (gcp-ml-ds@<company.org>). They create ML pipelines in the experimentation environment.
- *ML Engineers* (gcp-ml-eng@<company.org>). They handle and run the different environments, with access to all resources in order to troubleshoot possible issues with pipelines. 

The table below shows a high level overview of roles for each group on each project, using `READ`, `WRITE` and `ADMIN` access patterns for simplicity. For detailed roles please refer to the code.

|Group|CI/CD|Experimentation|Staging|Production|
|-|:-:|:-:|:-:|:-:|
|ML Engineers|`ADMIN`|`ADMIN`|`ADMIN`|`ADMIN`|
|Data Scientists|-|`READ`/`WRITE`|-|-|-|

This groups are not suitable for production grade environments. You can configure the groups via the yaml files in the different environments. 

### Git environment for the ML Pipelines

Make sure you have ready a Github repo with the ML pipeline code. 
You can clone the following example for setting up the repo: https://github.com/pbalm/professional-services/tree/vertex-mlops/examples/vertex_mlops_enterprise
This repo should have at least the following branches: `dev`, `staging`, `prod`

In latter stages you will need to provide both the Github organization and repo name:
`https://github.com/<ORG>/<REPO>`

See the [GIT Setup process](./GIT_SETUP.md)

##  Instructions

###  Deploy the CI/CD environment

- Go to the production folder: `cd 00-cicd`
- Create a `terraform.tfvars` file and specify the required variables
```tfm
prefix = "<prefix to be used for resources>"
billing_account = {
  id              = "000000-111111-22222222"
  organization_id = 000000000000
}
outputs_location = "./outputs"
```
- Edit the defaults YAML file :  `vi data/projects/defaults.yaml` and make sure the `billing_alert`, `essential_contacts` and default `labels` are correctly configured.
- Edit the project template YAML file based on the example file: `cp data/projects/cicd.yaml.sample data/projects/cicd.yaml` 
- Make sure you fill in the following parameters:
  - `folder_id `: Parent folder where the project will be created.
  - `identity_pool_claims`: Github organization and repo name using the format `attribute.repository/<ORG>/<REPO>`
- Make sure you have the right authentication setup (application default credentials, or a service account key)
- Run `terraform init` and `terraform apply`
- It is possible that some errors like `googleapi: Error 400: Service account xxxx does not exist.` appears. This is due to some dependencies with the Project IAM authoritative bindings of the service accounts. In this case, re-run again the process with `terraform apply`


###  Deploy the experimentation environment

- Go to the experimentation folder: `cd ../01-experimentation`
- Create a `terraform.tfvars` file and specify the required variables (you can copy the file you created for the CICD environment `cp ../00-cicd/terraform.tfvars .`)::

```tfm
prefix = "prefix"
billing_account = {
  id              = "000000-111111-22222222"
  organization_id = 000000000000
}
outputs_location = "./outputs"
```
- Edit the defaults YAML file :  `vi data/projects/defaults.yaml` and make sure the `billing_alert`, `essential_contacts` and default `labels` are correctly configured.
- Edit the project template YAML file based on the example file: `cp data/projects/creditcards-dev.yaml.sample data/projects/creditcards-dev.yaml` 
- Make sure you fill in the following parameters:
  - `folder_id `: Parent folder where the project will be created.
  - `group_iam`: Group to provide authoritative IAM bindings for the project
  - `notebooks`: Configuration data for creating Vertex Managed Workbenchs
- Make sure you have the right authentication setup (application default credentials, or a service account key)
- Run `terraform init` and `terraform apply`
- It is possible that some errors like `googleapi: Error 400: Service account xxxx does not exist.` appears. This is due to some dependencies with the Project IAM authoritative bindings of the service accounts. In this case, re-run again the process with `terraform apply`



###  Deploy the staging environment

- Go to the experimentation folder: `cd ../02-staging`
- Create a `terraform.tfvars` file and specify the required variables (you can copy the file you created for the CICD environment `cp ../00-cicd/terraform.tfvars .`)::

```tfm
prefix = "prefix"
billing_account = {
  id              = "000000-111111-22222222"
  organization_id = 000000000000
}
outputs_location = "./outputs"
```
- Edit the defaults YAML file :  `vi data/projects/defaults.yaml` and make sure the `billing_alert`, `essential_contacts` and default `labels` are correctly configured.
- Edit the project template YAML file based on the example file: `cp data/projects/creditcards-stg.yaml.sample data/projects/creditcards-stg.yaml` 
- Make sure you fill in the following parameters:
  - `folder_id `: Parent folder where the project will be created.
  - `group_iam`: Group to provide authoritative IAM bindings for the project
- Make sure you have the right authentication setup (application default credentials, or a service account key)
- Run `terraform init` and `terraform apply`
- It is possible that some errors like `googleapi: Error 400: Service account xxxx does not exist.` appears. This is due to some dependencies with the Project IAM authoritative bindings of the service accounts. In this case, re-run again the process with `terraform apply`


###  Deploy the production environment

- Go to the experimentation folder: `cd ../03-prod`
- Create a `terraform.tfvars` file and specify the required variables (you can copy the file you created for the CICD environment `cp ../00-cicd/terraform.tfvars .`)::

```tfm
prefix = "prefix"
billing_account = {
  id              = "000000-111111-22222222"
  organization_id = 000000000000
}
outputs_location = "./outputs"
```
- Edit the defaults YAML file :  `vi data/projects/defaults.yaml` and make sure the `billing_alert`, `essential_contacts` and default `labels` are correctly configured.
- Edit the project template YAML file based on the example file: `cp data/projects/creditcards-prd.yaml.sample data/projects/creditcards-prd.yaml` 
- Make sure you fill in the following parameters:
  - `folder_id `: Parent folder where the project will be created.
  - `group_iam`: Group to provide authoritative IAM bindings for the project
- Make sure you have the right authentication setup (application default credentials, or a service account key)
- Run `terraform init` and `terraform apply`
- It is possible that some errors like `googleapi: Error 400: Service account xxxx does not exist.` appears. This is due to some dependencies with the Project IAM authoritative bindings of the service accounts. In this case, re-run again the process with `terraform apply`


##  What's next?
Continue [setting up the GIT repo](./GIT_SETUP.md) and [launching the MLOps pipeline](./MLOPS.md).
