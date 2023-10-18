# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Organization <i>[org_id #0]</i>

| members | roles |
|---|---|
|<b>egov-test-0</b><br><small><i>group</i></small>|[roles/resourcemanager.organizationViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.organizationViewer) <code>+</code>|
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>prod-resman-net-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.orgFirewallPolicyAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.orgFirewallPolicyAdmin) <code>+</code><br>[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <code>+</code>|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>security-0</b><br><small><i>serviceAccount</i></small>|[roles/accesscontextmanager.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#accesscontextmanager.policyAdmin) <code>+</code>|

## Folder <i>development [#0]</i>

| members | roles |
|---|---|
|<b>dev-resman-dp-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>development [#1]</i>

| members | roles |
|---|---|
|<b>dev-resman-gke-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>development [#2]</i>

| members | roles |
|---|---|
|<b>dev-resman-dp-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin |
|<b>dev-resman-gke-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin |
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin |

## Folder <i>development [#3]</i>

| members | roles |
|---|---|
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>egov test 0 - core [#1]</i>

| members | roles |
|---|---|
|<b>egov-test-0</b><br><small><i>group</i></small>|organizations/[org_id #0]/roles/tenantLoadBalancerAdmin <br>[roles/compute.instanceAdmin.v1](https://cloud.google.com/iam/docs/understanding-roles#compute.instanceAdmin.v1) <br>[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |
|<b>egov-t0-iac-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/tenantLoadBalancerAdmin <br>[roles/compute.instanceAdmin.v1](https://cloud.google.com/iam/docs/understanding-roles#compute.instanceAdmin.v1) <br>[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |
|<b>tn-egov-t0-0</b><br><small><i>serviceAccount</i></small>|[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) |

## Folder <i>egov test 0 - tenant [#1]</i>

| members | roles |
|---|---|
|<b>egov-test-0</b><br><small><i>group</i></small>|[roles/cloudasset.owner](https://cloud.google.com/iam/docs/understanding-roles#cloudasset.owner) <br>[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) <br>[roles/resourcemanager.tagUser](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.tagUser) |
|<b>egov-t0-iac-0</b><br><small><i>serviceAccount</i></small>|[roles/cloudasset.owner](https://cloud.google.com/iam/docs/understanding-roles#cloudasset.owner) <br>[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) <br>[roles/resourcemanager.tagUser](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.tagUser) |

## Folder <i>egov test 0 [#1]</i>

| members | roles |
|---|---|
|<b>egov-test-0</b><br><small><i>group</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/monitoring.admin](https://cloud.google.com/iam/docs/understanding-roles#monitoring.admin) <br>[roles/resourcemanager.folderViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderViewer) <br>[roles/browser](https://cloud.google.com/iam/docs/understanding-roles#browser) |
|<b>egov-t0-iac-0</b><br><small><i>serviceAccount</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/monitoring.admin](https://cloud.google.com/iam/docs/understanding-roles#monitoring.admin) <br>[roles/resourcemanager.folderViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderViewer) |
|<b>tn-egov-t0-0</b><br><small><i>serviceAccount</i></small>|[roles/cloudasset.owner](https://cloud.google.com/iam/docs/understanding-roles#cloudasset.owner) <br>[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) <br>[roles/resourcemanager.tagUser](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.tagUser) |

## Folder <i>networking</i>

| members | roles |
|---|---|
|<b>gcp-network-admins</b><br><small><i>group</i></small>|[roles/editor](https://cloud.google.com/iam/docs/understanding-roles#editor) |
|<b>prod-resman-net-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>production [#0]</i>

| members | roles |
|---|---|
|<b>prod-resman-dp-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>production [#1]</i>

| members | roles |
|---|---|
|<b>prod-resman-gke-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>production [#2]</i>

| members | roles |
|---|---|
|<b>prod-resman-dp-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin |
|<b>prod-resman-gke-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin |
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin |

## Folder <i>production [#3]</i>

| members | roles |
|---|---|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>sandbox</i>

| members | roles |
|---|---|
|<b>dev-resman-sbox-0</b><br><small><i>serviceAccount</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>security</i>

| members | roles |
|---|---|
|<b>gcp-security-admins</b><br><small><i>group</i></small>|[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |
|<b>security-0</b><br><small><i>serviceAccount</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>team 0</i>

| members | roles |
|---|---|
|<b>prod-teams-team-0-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>teams</i>

| members | roles |
|---|---|
|<b>prod-resman-teams-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Project <i>egov-t0-iac-core-0</i>

| members | roles |
|---|---|
|<b>egov-test-0</b><br><small><i>group</i></small>|[roles/iam.serviceAccountAdmin](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountAdmin) <br>[roles/iam.serviceAccountTokenCreator](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountTokenCreator) <br>[roles/iam.workloadIdentityPoolAdmin](https://cloud.google.com/iam/docs/understanding-roles#iam.workloadIdentityPoolAdmin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|

## Project <i>prod-iac-core-0</i>

| members | roles |
|---|---|
|<b>dev-resman-dp-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>dev-resman-gke-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>dev-resman-sbox-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-gke-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-net-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-net-1</b><br><small><i>serviceAccount</i></small>|[roles/logging.logWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.logWriter) <code>+</code>|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-sec-1</b><br><small><i>serviceAccount</i></small>|[roles/logging.logWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.logWriter) <code>+</code>|
|<b>prod-resman-teams-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>security-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>tn-egov-t0-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
