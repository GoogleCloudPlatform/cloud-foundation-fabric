# CI/CD Notes

## Resource management

- check out the repository and enter the folder
- copy files from the `01-resman` stage
- copy the workflow file from output files
- set the `outputs_location` variable to `null` and apply locally

## Modules repository authentication

- create a SSH key pair
- create a [deploy key](https://docs.github.com/en/developers/overview/managing-deploy-keys#deploy-keys) in the modules repository
- set up a secret in the stage repository named `CICD_MODULES_KEY` with the private key
