# MLOps with Vertex AI

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

##  Instructions

###  Deploy the experimentation environment

- Go to the experimentation folder: `cd experimentation`
- Create a `terraform.tfvars` file and specify the required variables:

```tfm
prefix = "prefix"
billing_account = {
  id              = "000000-111111-22222222"
  organization_id = 000000000000
}
outputs_location = "./outputs"
```
- Edit the projects YAML file: `vi data/projects/credit-cards.yaml` 
- Make sure you fill in the following parameters:
```
essential_contacts:
folder_id: 
notebooks:
  name:
    owner:
```


- Make sure you have the right authentication setup (application default credentials, or a service account key)
- Run `terraform init` and `terraform apply`
- It is possible that some errors like `googleapi: Error 400: Service account xxxx does not exist.` appears. This is due to some dependencies with the Project IAM authoritative bindings of the service accounts. In this case, re-run again the process with `terraform apply`


###  Deploy the CI/CD environment

- Go to the production folder: `cd ../prod`
- Create a `terraform.tfvars` file and specify the required variables (you can copy the file you created for the experimentation dir):
```tfm
prefix = "prefix"
billing_account = {
  id              = "000000-111111-22222222"
  organization_id = 000000000000
}
outputs_location = "./outputs"
```

- Edit the projects YAML file: `vi data/projects/credit-cards.yaml` 
- Make sure you fill in the following parameters:
```
essential_contacts:
folder_id: 
workload_identity:
  identity_pool_claims: 
```

- Make sure you have the right authentication setup (application default credentials, or a service account key)
- Run `terraform init` and `terraform apply`
- It is possible that some errors like `googleapi: Error 400: Service account xxxx does not exist.` appears. This is due to some dependencies with the Project IAM authoritative bindings of the service accounts. In this case, re-run again the process with `terraform apply`
