# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Organization <i>[org_id #0]</i>

| members | roles |
|---|---|
|<b>tn0-admins</b><br><small><i>group</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code><br>[roles/resourcemanager.organizationViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.organizationViewer) <code>+</code>|
|<b>tn0-gke-dev-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>tn0-gke-prod-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>tn0-networking-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>tn0-pf-dev-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>tn0-pf-prod-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>tn0-resman-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>tn0-sandbox-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>tn0-security-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>tn0-teams-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|

## Folder <i>test tenant 0 [#1]</i>

| members | roles |
|---|---|
|<b>tn0-admins</b><br><small><i>group</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |
|<b>tn0-networking-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) |
|<b>tn0-resman-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Project <i>prod-iac-core-0</i>

| members | roles |
|---|---|
|<b>tn0-bootstrap-1</b><br><small><i>serviceAccount</i></small>|[roles/logging.logWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.logWriter) <code>+</code>|

## Project <i>tn0-audit-logs-0</i>

| members | roles |
|---|---|
|<b>f260055713332-284719</b><br><small><i>serviceAccount</i></small>|[roles/logging.bucketWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.bucketWriter) <code>+</code><code>•</code>|
|<b>prod-resman-0</b><br><small><i>serviceAccount</i></small>|[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) |
|<b>tn0-resman-0</b><br><small><i>serviceAccount</i></small>|[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) |

## Project <i>tn0-iac-core-0</i>

| members | roles |
|---|---|
|<b>tn0-admins</b><br><small><i>group</i></small>|[roles/iam.serviceAccountTokenCreator](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountTokenCreator) <br>[roles/iam.workloadIdentityPoolAdmin](https://cloud.google.com/iam/docs/understanding-roles#iam.workloadIdentityPoolAdmin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>prod-resman-0</b><br><small><i>serviceAccount</i></small>|[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) |
|<b>tn0-resman-0</b><br><small><i>serviceAccount</i></small>|[roles/cloudbuild.builds.editor](https://cloud.google.com/iam/docs/understanding-roles#cloudbuild.builds.editor) <br>[roles/iam.serviceAccountAdmin](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountAdmin) <br>[roles/iam.workloadIdentityPoolAdmin](https://cloud.google.com/iam/docs/understanding-roles#iam.workloadIdentityPoolAdmin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/source.admin](https://cloud.google.com/iam/docs/understanding-roles#source.admin) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
