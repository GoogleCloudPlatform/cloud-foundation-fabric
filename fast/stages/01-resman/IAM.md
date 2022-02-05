# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Organization <i>[org_id #0]</i>

| members | roles |
|---|---|
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/billing.costsManager](https://cloud.google.com/iam/docs/understanding-roles#billing.costsManager) <code>+</code><br>[roles/billing.user](https://cloud.google.com/iam/docs/understanding-roles#billing.user) <code>+</code><br>[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code>|
|<b>prod-resman-networking-0</b><br><small><i>serviceAccount</i></small>|[roles/billing.user](https://cloud.google.com/iam/docs/understanding-roles#billing.user) <code>+</code><br>[roles/compute.orgFirewallPolicyAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.orgFirewallPolicyAdmin) <code>+</code><br>[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <code>+</code>|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/billing.costsManager](https://cloud.google.com/iam/docs/understanding-roles#billing.costsManager) <code>+</code><br>[roles/billing.user](https://cloud.google.com/iam/docs/understanding-roles#billing.user) <code>+</code><br>[roles/orgpolicy.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#orgpolicy.policyAdmin) <code>+</code>|
|<b>prod-resman-security-0</b><br><small><i>serviceAccount</i></small>|[roles/accesscontextmanager.policyAdmin](https://cloud.google.com/iam/docs/understanding-roles#accesscontextmanager.policyAdmin) <code>+</code><br>[roles/billing.user](https://cloud.google.com/iam/docs/understanding-roles#billing.user) <code>+</code>|

## Folder <i>networking</i>

| members | roles |
|---|---|
|<b>gcp-network-admins</b><br><small><i>group</i></small>|[roles/editor](https://cloud.google.com/iam/docs/understanding-roles#editor) |
|<b>prod-resman-networking-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) <br>[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>sandbox</i>

| members | roles |
|---|---|
|<b>dev-resman-sandbox-0</b><br><small><i>serviceAccount</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>security</i>

| members | roles |
|---|---|
|<b>gcp-security-admins</b><br><small><i>group</i></small>|[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |
|<b>prod-resman-security-0</b><br><small><i>serviceAccount</i></small>|[roles/logging.admin](https://cloud.google.com/iam/docs/understanding-roles#logging.admin) <br>[roles/owner](https://cloud.google.com/iam/docs/understanding-roles#owner) <br>[roles/resourcemanager.folderAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.folderAdmin) <br>[roles/resourcemanager.projectCreator](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectCreator) |

## Folder <i>dev</i>

| members | roles |
|---|---|
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) |

## Folder <i>prod</i>

| members | roles |
|---|---|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.xpnAdmin](https://cloud.google.com/iam/docs/understanding-roles#compute.xpnAdmin) |
