# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Organization
| members | roles |
|---|---|
|<b></b><br><small><i>domain</i></small>|roles/browser <br>roles/resourcemanager.organizationViewer |
|<b>gcp-network-admins</b><br><small><i>group</i></small>|roles/cloudasset.owner <br>roles/cloudsupport.techSupportEditor <br>roles/compute.orgFirewallPolicyAdmin <code>+</code><br>roles/compute.xpnAdmin <code>+</code>|
|<b>gcp-organization-admins</b><br><small><i>group</i></small>|roles/cloudasset.owner <br>roles/cloudsupport.admin <br>roles/compute.osAdminLogin <br>roles/compute.osLoginExternalUser <br>roles/owner <br>roles/resourcemanager.folderAdmin <br>roles/resourcemanager.organizationAdmin <br>roles/resourcemanager.projectCreator <br>roles/billing.admin <code>+</code>|
|<b>gcp-security-admins</b><br><small><i>group</i></small>|roles/cloudasset.owner <br>roles/cloudsupport.techSupportEditor <br>roles/iam.securityReviewer <br>roles/logging.admin <br>roles/securitycenter.admin <br>roles/accesscontextmanager.policyAdmin <code>+</code><br>roles/iam.organizationRoleAdmin <code>+</code><br>roles/orgpolicy.policyAdmin <code>+</code>|
|<b>gcp-support</b><br><small><i>group</i></small>|roles/cloudsupport.techSupportEditor <br>roles/logging.viewer <br>roles/monitoring.viewer |
|<b>prod-bootstrap-0</b><br><small><i>serviceAccount</i></small>|roles/logging.admin <br>roles/resourcemanager.organizationAdmin <br>roles/resourcemanager.projectCreator <br>roles/billing.admin <code>+</code><br>roles/iam.organizationRoleAdmin <code>+</code>|
|<b>prod-resman-0</b><br><small><i>serviceAccount</i></small>|organizations/436789450919/roles/organizationIamAdmin <code>•</code><br>roles/resourcemanager.folderAdmin <br>roles/billing.admin <code>+</code><br>roles/orgpolicy.policyAdmin <code>+</code>|

## Project <i>prod-audit-logs-0</i>

| members | roles |
|---|---|
|<b>prod-bootstrap-0</b><br><small><i>serviceAccount</i></small>|roles/owner |

## Project <i>prod-billing-export-0</i>

| members | roles |
|---|---|
|<b>prod-bootstrap-0</b><br><small><i>serviceAccount</i></small>|roles/owner |

## Project <i>prod-iac-core-0</i>

| members | roles |
|---|---|
|<b>gcp-devops</b><br><small><i>group</i></small>|roles/iam.serviceAccountAdmin <br>roles/iam.serviceAccountTokenCreator |
|<b>gcp-organization-admins</b><br><small><i>group</i></small>|roles/iam.serviceAccountTokenCreator |
|<b>prod-bootstrap-0</b><br><small><i>serviceAccount</i></small>|roles/iam.serviceAccountAdmin <br>roles/owner <br>roles/storage.admin |
|<b>prod-resman-0</b><br><small><i>serviceAccount</i></small>|roles/iam.serviceAccountAdmin <br>roles/storage.admin |
