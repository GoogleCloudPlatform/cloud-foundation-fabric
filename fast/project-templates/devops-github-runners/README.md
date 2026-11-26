# Self-Hosted GitHub Actions Runners on Cloud Run Worker Pools (CREMA)

This FAST project template deploys scale-to-zero, organization-level self-hosted GitHub Actions runners on **Cloud Run Worker Pools**, autoscaled by **[CREMA (Cloud Run External Metrics Autoscaling)](https://github.com/GoogleCloudPlatform/cloud-run-external-metrics-autoscaling)** with GitHub App Just-In-Time (JIT) ephemeral registration.

## Architecture

- **Project Prerequisites (`project.yaml`):** Provisioned via FAST Project Factory (or used as a checklist). Enables required APIs and creates least-privilege service accounts (`crema-autoscaler-sa` and `worker-pool-sa`).
- **Cloud Run Worker Pool (`worker-pool.tf`):** Composes `modules/cloud-run-v2` (`type = "WORKERPOOL"`, `managed_revision = false`), mounting the GitHub App private key from Secret Manager and ignoring live `scaling[0].manual_instance_count` mutations performed by CREMA.
- **CREMA Autoscaler (`crema.tf` & `parameters.tf`):** Composes `modules/cloud-run-v2` (`type = "SERVICE"`, `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER`, `cpu_idle = false`) reading a content-hashed regional Parameter Manager `CremaConfig` to scale the worker pool between `0` and `max_replicas`.
- **Regional Org-Policy Compliance (`secrets.tf` & `scripts/build_and_push.sh`):** Uses regional user-managed Secret Manager replication, regional Parameter Manager, and regional user-owned Cloud Build staging buckets.

## Usage

### 1. Provision the Project

Copy `project.yaml` into your FAST Project Factory dataset (setting `parent` to your DevOps folder) and apply it, or enable the listed APIs and create `crema-autoscaler-sa` and `worker-pool-sa` manually.

### 2. Upload GitHub App Private Key & Build Runner Image

After creating the secrets and Artifact Registry repository, upload your GitHub App `.pem` key out-of-band and build the JIT runner image:

```bash
gcloud secrets versions add github-app-private-key \
  --project="YOUR_PROJECT_ID" \
  --data-file="/path/to/app.private-key.pem"

PROJECT_ID="YOUR_PROJECT_ID" REGION="us-central1" ./scripts/build_and_push.sh
```

### 3. Deploy the Template

```hcl
module "github-runners" {
  source   = "./fabric/fast/project-templates/devops-github-runners"
  location = "us-central1"
  project_config = {
    project_id = "my-devops-runners-0"
    number     = 123456789012
  }
  github_config = {
    org             = "my-github-org"
    app_id          = "123456"
    installation_id = "12345678"
  }
}
```

<!-- BEGIN TFDOC -->
<!-- END TFDOC -->
