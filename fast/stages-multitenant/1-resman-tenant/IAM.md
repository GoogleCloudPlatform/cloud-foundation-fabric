# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Folder <i>development [#0]</i>

| members | roles |
|---|---|
|<b>tn0-gke-dev-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>development [#1]</i>

| members | roles |
|---|---|
|<b>tn0-gke-dev-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin |
|<b>tn0-pf-dev-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin |

## Folder <i>networking</i>

| members | roles |
|---|---|
|<b>tn0-networking-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>production [#0]</i>

| members | roles |
|---|---|
|<b>tn0-gke-prod-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>production [#1]</i>

| members | roles |
|---|---|
|<b>tn0-gke-prod-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin |
|<b>tn0-pf-prod-0</b><br><small><i>serviceAccount</i></small>|organizations/[org_id #0]/roles/serviceProjectNetworkAdmin |

## Folder <i>sandbox</i>

| members | roles |
|---|---|
|<b>tn0-sandbox-0</b><br><small><i>serviceAccount</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>security</i>

| members | roles |
|---|---|
|<b>tn0-security-0</b><br><small><i>serviceAccount</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>teams</i>

| members | roles |
|---|---|
|<b>tn0-teams-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>test tenant 0</i>

| members | roles |
|---|---|
|<b>tn0-networking-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.orgFirewallPolicyAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.orgFirewallPolicyAdmin) <code>+</code><br>[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <code>+</code>|
|<b>tn0-security-0</b><br><small><i>serviceAccount</i></small>|[roles/accesscontextmanager.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#accesscontextmanager.policyAdmin) <code>+</code>|
