# Gitlab notes

## Open points

- [ ] WIF
- [ ] Structure groups and projects
- [x] Bootstrap groups, projects and repository

## How to run this stage:

Connect to Gitlab as detailed in the 0-infra [README.md](./../0-infra/README.md) as root user and create a personal access token.
Set the newly created personal access as `gitlab_access_token` variable and then issue the following commands:

```bash
gcloud alpha storage cp gs://${prefix}-prod-iac-core-outputs-0/workflows/*-workflow.yaml ./workflows/
```

Set `http_proxy` and `https_proxy` env vars to http://localhost:3128 and then run:

```bash
terraform init
terraform apply
```

Try to create a merge request to trigger a CI pipeline on one of FAST stages

