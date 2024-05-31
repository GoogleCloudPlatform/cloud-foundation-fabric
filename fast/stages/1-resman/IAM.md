# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Organization <i>[organization #0]</i>

| members | roles |
|---|---|
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>prod-resman-net-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.orgFirewallPolicyAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.orgFirewallPolicyAdmin) <code>+</code><br>[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <code>+</code>|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code><code>•</code>|
|<b>prod-resman-sec-0</b><br><small><i>serviceAccount</i></small>|[roles/cloudasset.viewer](https://cloud.google.com/iam/docs/understanding-roles#cloudasset.viewer) <code>+</code><br>[roles/accesscontextmanager.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#accesscontextmanager.policyAdmin) <code>+</code>|

## Folder <i>data platform/development</i>

| members | roles |
|---|---|
|<b>dev-resman-dp-0</b><br><small><i>serviceAccount</i></small>|organizations/[organization #0]/roles/serviceProjectNetworkAdmin <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |
|<b>dev-resman-dp-0r</b><br><small><i>serviceAccount</i></small>|[roles/resourcemanager.folderViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderViewer) <br>[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |

## Folder <i>data platform/production</i>

| members | roles |
|---|---|
|<b>prod-resman-dp-0</b><br><small><i>serviceAccount</i></small>|organizations/[organization #0]/roles/serviceProjectNetworkAdmin <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |
|<b>prod-resman-dp-0r</b><br><small><i>serviceAccount</i></small>|[roles/resourcemanager.folderViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderViewer) <br>[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |

## Folder <i>gke/development</i>

| members | roles |
|---|---|
|<b>dev-resman-gke-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |
|<b>dev-resman-gke-0r</b><br><small><i>serviceAccount</i></small>|[roles/resourcemanager.folderViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderViewer) <br>[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |

## Folder <i>gke/production</i>

| members | roles |
|---|---|
|<b>prod-resman-gke-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |
|<b>prod-resman-gke-0r</b><br><small><i>serviceAccount</i></small>|[roles/resourcemanager.folderViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderViewer) <br>[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |

## Folder <i>networking</i>

| members | roles |
|---|---|
|<b>gcp-network-admins</b><br><small><i>group</i></small>|[roles/editor](https://cloud.google.com/iam/docs/understanding-roles#editor) |
|<b>prod-resman-net-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |
|<b>prod-resman-net-0r</b><br><small><i>serviceAccount</i></small>|[roles/resourcemanager.folderViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderViewer) <br>[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |

## Folder <i>networking/development</i>

| members | roles |
|---|---|
|<b>dev-resman-dp-0</b><br><small><i>serviceAccount</i></small>|organizations/[organization #0]/roles/serviceProjectNetworkAdmin |
|<b>dev-resman-dp-0r</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkViewer](https://cloud.google.com/iam/docs/understanding-roles#compute.networkViewer) |
|<b>dev-resman-gke-0</b><br><small><i>serviceAccount</i></small>|organizations/[organization #0]/roles/serviceProjectNetworkAdmin |
|<b>dev-resman-gke-0r</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkViewer](https://cloud.google.com/iam/docs/understanding-roles#compute.networkViewer) |
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|organizations/[organization #0]/roles/serviceProjectNetworkAdmin |
|<b>dev-resman-pf-0r</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkViewer](https://cloud.google.com/iam/docs/understanding-roles#compute.networkViewer) |

## Folder <i>networking/production</i>

| members | roles |
|---|---|
|<b>prod-resman-dp-0</b><br><small><i>serviceAccount</i></small>|organizations/[organization #0]/roles/serviceProjectNetworkAdmin |
|<b>prod-resman-dp-0r</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkViewer](https://cloud.google.com/iam/docs/understanding-roles#compute.networkViewer) |
|<b>prod-resman-gke-0</b><br><small><i>serviceAccount</i></small>|organizations/[organization #0]/roles/serviceProjectNetworkAdmin |
|<b>prod-resman-gke-0r</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkViewer](https://cloud.google.com/iam/docs/understanding-roles#compute.networkViewer) |
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|organizations/[organization #0]/roles/serviceProjectNetworkAdmin |
|<b>prod-resman-pf-0r</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkViewer](https://cloud.google.com/iam/docs/understanding-roles#compute.networkViewer) |

## Folder <i>sandbox</i>

| members | roles |
|---|---|
|<b>dev-resman-sbox-0</b><br><small><i>serviceAccount</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>security</i>

| members | roles |
|---|---|
|<b>gcp-security-admins</b><br><small><i>group</i></small>|[roles/editor](https://cloud.google.com/iam/docs/understanding-roles#editor) |
|<b>prod-resman-sec-0</b><br><small><i>serviceAccount</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |
|<b>prod-resman-sec-0r</b><br><small><i>serviceAccount</i></small>|[roles/resourcemanager.folderViewer](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderViewer) <br>[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |

## Project <i>prod-iac-core-0</i>

| members | roles |
|---|---|
|<b>dev-resman-dp-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>dev-resman-dp-0r</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>dev-resman-gke-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>dev-resman-gke-0r</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>dev-resman-pf-0r</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>dev-resman-sbox-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-dp-0r</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-gke-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-gke-0r</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-net-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-net-0r</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-net-1</b><br><small><i>serviceAccount</i></small>|[roles/logging.logWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.logWriter) <code>+</code>|
|<b>prod-resman-net-1r</b><br><small><i>serviceAccount</i></small>|[roles/logging.logWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.logWriter) <code>+</code>|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-pf-0r</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-sec-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-sec-0r</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-sec-1</b><br><small><i>serviceAccount</i></small>|[roles/logging.logWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.logWriter) <code>+</code>|
|<b>prod-resman-sec-1r</b><br><small><i>serviceAccount</i></small>|[roles/logging.logWriter](https://cloud.google.com/iam/docs/understanding-roles#logging.logWriter) <code>+</code>|
|<b>prod-resman-teams-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
|<b>prod-resman-test-3-0</b><br><small><i>serviceAccount</i></small>|[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <code>+</code>|
