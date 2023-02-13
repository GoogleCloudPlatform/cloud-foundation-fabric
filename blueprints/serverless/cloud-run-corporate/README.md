# Cloud Run Corporate

## Introduction

This blueprint contains all the necessary Terraform modules to build and privately expose a Cloud Run service in a variety of use cases.

The content of this blueprint corresponds to the chapter '_Developing an enterprise application - The corporate environment_' of the __Serverless Networking Guide__ (to be released soon). This guide is an easy to follow introduction to Cloud Run, where a couple of friendly characters will guide you from the basics to more advanced topics with a very practical approach and in record time! The code here complements this learning and allows you to test the scenarios presented and your knowledge.

## Architecture

## Prerequisites

## Spinning up the architecture

### General steps

1. Clone the repo to your local machine or Cloud Shell:
```bash
git clone https://github.com/GoogleCloudPlatform/cloud-foundation-fabric
```

2. Change to the directory of the blueprint:
```bash
cd cloud-foundation-fabric/blueprints/serverless/cloud-run-corporate
```
You should see this README and some terraform files.

3. To deploy a specific use case, you will need to create a file in this directory called `terraform.tfvars` and follow the corresponding instructions to set variables. Sometimes values that are meant to be substituted will be shown inside brackets but you need to omit these brackets. E.g.:
```tfvars
project_id = "[your-project_id]"
```
may become
```tfvars
project_id = "spiritual-hour-331417"
```

Although each use case is somehow built around the previous one they are self-contained so you can deploy any of them at will.

4. The usual terraform commands will do the work:
```bash
terraform init
terraform plan
terraform apply
```

The resource creation will take a few minutes but when it’s complete, you should see an output stating the command completed successfully with a list of the created resources, and some output variables with information to access your service.

__Congratulations!__ You have successfully deployed the use case you chose based on the variables configuration.

### Use case 1: Access to Cloud Run from a VM in the project

### Use case 2:

### Use case 3:

### Use case 4:

### Use case 5:

## Cleaning up your environment

The easiest way to remove all the deployed resources is to run the following command:
```bash
terraform destroy
```
The above command will delete the associated resources so there will be no billable charges made afterwards. IAP Brands, though, can only be created once per project and not deleted. Destroying a Terraform-managed IAP Brand will remove it from state but will not delete it from Google Cloud.
<!-- BEGIN TFDOC -->

<!-- END TFDOC -->

## Tests
