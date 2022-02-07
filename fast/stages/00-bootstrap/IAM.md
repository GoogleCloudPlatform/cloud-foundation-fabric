# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Organization <i>[org_id #0]</i>

| members | roles |
|---|---|
|<b></b><br><small><i>domain</i></small>|[roles/browser](https://cloud.google.com/iam/docs/understanding-roles#browser) <br>[roles/resourcemanager.organizationViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.organizationViewer) |
|<b>gcp-network-admins</b><br><small><i>group</i></small>|[roles/cloudasset.owner](https://cloud.google.com/iam/docs/understanding-roles#cloudasset.owner) <br>[roles/cloudsupport.techSupportEditor](https://cloud.google.com/iam/docs/understanding-roles#cloudsupport.techSupportEditor) <br>[roles/compute.orgFirewallPolicyAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.orgFirewallPolicyAdmin) <code>+</code><br>[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <code>+</code>|
|<b>gcp-organization-admins</b><br><small><i>group</i></small>|[roles/cloudasset.owner](https://cloud.google.com/iam/docs/understanding-roles#cloudasset.owner) <br>[roles/cloudsupport.admin](https://cloud.google.com/iam/docs/understanding-roles#cloudsupport.admin) <br>[roles/compute.osAdminLogin](https://cloud.google.com/iam/docs/understanding-roles#compute.osAdminLogin) <br>[roles/compute.osLoginExternalUser](https://cloud.google.com/iam/docs/understanding-roles#compute.osLoginExternalUser) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.organizationAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.organizationAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) <br>[roles/billing.admin](https://cloud.google.com/iam/docs/understanding-roles#billing.admin) <code>+</code>|
|<b>gcp-security-admins</b><br><small><i>group</i></small>|[roles/cloudasset.owner](https://cloud.google.com/iam/docs/understanding-roles#cloudasset.owner) <br>[roles/cloudsupport.techSupportEditor](https://cloud.google.com/iam/docs/understanding-roles#cloudsupport.techSupportEditor) <br>[roles/iam.securityReviewer](https://cloud.google.com/iam/docs/understanding-roles#iam.securityReviewer) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/securitycenter.admin](https://cloud.google.com/iam/docs/understanding-roles#securitycenter.admin) <br>[roles/accesscontextmanager.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#accesscontextmanager.policyAdmin) <code>+</code><br>[roles/iam.organizationRoleAdmin](https://cloud.google.com/iam/docs/understanding-roles#iam.organizationRoleAdmin) <code>+</code><br>[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code>|
|<b>gcp-support</b><br><small><i>group</i></small>|[roles/cloudsupport.techSupportEditor](https://cloud.google.com/iam/docs/understanding-roles#cloudsupport.techSupportEditor) <br>[roles/logging.viewer](https://cloud.google.com/iam/docs/understanding-roles#logging.viewer) <br>[roles/monitoring.viewer](https://cloud.google.com/iam/docs/understanding-roles#monitoring.viewer) |
|<b>prod-bootstrap-0</b><br><small><i>serviceAccount</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/resourcemanager.organizationAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.organizationAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) <br>[roles/billing.admin](https://cloud.google.com/iam/docs/understanding-roles#billing.admin) <code>+</code><br>[roles/iam.organizationRoleAdmin](https://cloud.google.com/iam/docs/understanding-roles#iam.organizationRoleAdmin) <code>+</code>|
|<b>prod-resman-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/organizationIamAdmin <code>•</code><br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/billing.admin](https://cloud.google.com/iam/docs/understanding-roles#billing.admin) <code>+</code><br>[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code>|

## Project <i>prod-audit-logs-0</i>

| members | roles |
|---|---|
|<b>prod-bootstrap-0</b><br><small><i>serviceAccount</i></small>|[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) |

## Project <i>prod-billing-export-0</i>

| members | roles |
|---|---|
|<b>prod-bootstrap-0</b><br><small><i>serviceAccount</i></small>|[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) |

## Project <i>prod-iac-core-0</i>

| members | roles |
|---|---|
|<b>gcp-devops</b><br><small><i>group</i></small>|[roles/iam.serviceAccountAdmin](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountAdmin) <br>[roles/iam.serviceAccountTokenCreator](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountTokenCreator) |
|<b>gcp-organization-admins</b><br><small><i>group</i></small>|[roles/iam.serviceAccountTokenCreator](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountTokenCreator) |
|<b>prod-bootstrap-0</b><br><small><i>serviceAccount</i></small>|[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) |
|<b>prod-resman-0</b><br><small><i>serviceAccount</i></small>|[roles/iam.serviceAccountAdmin](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountAdmin) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
