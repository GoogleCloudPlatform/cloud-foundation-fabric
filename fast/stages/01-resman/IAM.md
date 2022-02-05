# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Organization
| members | roles |
|---|---|
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|roles/billing.costsManager <code>+</code><br>roles/billing.user <code>+</code><br>roles/orgpolicy.policyAdmin <code>+</code>|
|<b>prod-resman-networking-0</b><br><small><i>serviceAccount</i></small>|roles/billing.user <code>+</code><br>roles/compute.orgFirewallPolicyAdmin <code>+</code><br>roles/compute.xpnAdmin <code>+</code>|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|roles/billing.costsManager <code>+</code><br>roles/billing.user <code>+</code><br>roles/orgpolicy.policyAdmin <code>+</code>|
|<b>prod-resman-security-0</b><br><small><i>serviceAccount</i></small>|roles/accesscontextmanager.policyAdmin <code>+</code><br>roles/billing.user <code>+</code>|

## Folder <i>networking</i>

| members | roles |
|---|---|
|<b>gcp-network-admins</b><br><small><i>group</i></small>|roles/editor |
|<b>prod-resman-networking-0</b><br><small><i>serviceAccount</i></small>|roles/compute.xpnAdmin <br>roles/logging.admin <br>roles/owner <br>roles/resourcemanager.folderAdmin <br>roles/resourcemanager.projectCreator |

## Folder <i>sandbox</i>

| members | roles |
|---|---|
|<b>dev-resman-sandbox-0</b><br><small><i>serviceAccount</i></small>|roles/logging.admin <br>roles/owner <br>roles/resourcemanager.folderAdmin <br>roles/resourcemanager.projectCreator |

## Folder <i>security</i>

| members | roles |
|---|---|
|<b>gcp-security-admins</b><br><small><i>group</i></small>|roles/viewer |
|<b>prod-resman-security-0</b><br><small><i>serviceAccount</i></small>|roles/logging.admin <br>roles/owner <br>roles/resourcemanager.folderAdmin <br>roles/resourcemanager.projectCreator |

## Folder <i>dev</i>

| members | roles |
|---|---|
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|roles/compute.xpnAdmin |

## Folder <i>prod</i>

| members | roles |
|---|---|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|roles/compute.xpnAdmin |
