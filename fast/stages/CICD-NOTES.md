# CI/CD Notes

## Resource management

- check out the repository and enter the folder
- copy files from the `01-resman` stage
- create or copy tfvars file for stage 01 variables setting `outputs_location` to `null`
- copy the workflow file from output files

## Module sources

regexp find `source\s*= "../../../modules/([^"]+)"`

regexp replace `source = "git@github.com:ludomagno/fast-0-modules.git//$1?ref=v1.0"`

## Modules repository authentication

- create a SSH key pair
- create a [deploy key](https://docs.github.com/en/developers/overview/managing-deploy-keys#deploy-keys) in the modules repository
- set up a secret in the stage repository named `CICD_MODULES_KEY` with the private key
