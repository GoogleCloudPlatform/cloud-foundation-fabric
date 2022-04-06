# CI/CD Notes

## Resource management

- check out the repository and enter the folder
- copy files for the `01-resman` stage
- copy assets from `fast`

## Modules repository

- [authentication from actions](https://maelvls.dev/gh-actions-with-tf-private-repo/)
- [private repositories as modules](https://wahlnetwork.com/2020/08/11/using-private-git-repositories-as-terraform-modules/)

## Actions

- [terraform-github-actions](https://github.com/dflook/terraform-github-actions/tree/master/terraform-plan)

## Module renaming

```bash
source\s*= "../../../modules([^"]+)"
source = "git@github.com:ludomagno/fast-0-modules.git//$1?ref=v1.0"
```

## Modules repository authentication

- create a SSH key pair
- create a [deploy key](https://docs.github.com/en/developers/overview/managing-deploy-keys#deploy-keys) in the modules repository
- set up a secret in the stage repository named `CICD_MODULES_KEY` with the private key
