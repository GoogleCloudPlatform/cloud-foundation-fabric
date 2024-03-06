# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Project <i>dev-net-spoke-0</i>

| members | roles |
|---|---|
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>dev-resman-dp-0</b><br><small><i>serviceAccount</i></small>|[roles/resourcemanager.projectIamAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectIamAdmin) <code>•</code>|
|<b>dev-resman-gke-0</b><br><small><i>serviceAccount</i></small>|[roles/dns.admin](https://cloud.google.com/iam/docs/understanding-roles#dns.admin) <br>[roles/resourcemanager.projectIamAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectIamAdmin) <code>•</code>|
|<b>dev-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/dns.admin](https://cloud.google.com/iam/docs/understanding-roles#dns.admin) <br>[roles/resourcemanager.projectIamAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectIamAdmin) <code>•</code>|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/dns.admin](https://cloud.google.com/iam/docs/understanding-roles#dns.admin) <br>[roles/resourcemanager.projectIamAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectIamAdmin) <code>•</code>|

## Project <i>prod-net-landing-0</i>

| members | roles |
|---|---|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|organizations/[organization #0]/roles/serviceProjectNetworkAdmin <br>[roles/dns.admin](https://cloud.google.com/iam/docs/understanding-roles#dns.admin) |

## Project <i>prod-net-spoke-0</i>

| members | roles |
|---|---|
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>prod-resman-dp-0</b><br><small><i>serviceAccount</i></small>|[roles/resourcemanager.projectIamAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectIamAdmin) <code>•</code>|
|<b>prod-resman-gke-0</b><br><small><i>serviceAccount</i></small>|[roles/dns.admin](https://cloud.google.com/iam/docs/understanding-roles#dns.admin) <br>[roles/resourcemanager.projectIamAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectIamAdmin) <code>•</code>|
|<b>prod-resman-pf-0</b><br><small><i>serviceAccount</i></small>|[roles/dns.admin](https://cloud.google.com/iam/docs/understanding-roles#dns.admin) <br>[roles/resourcemanager.projectIamAdmin](https://cloud.google.com/iam/docs/understanding-roles#resourcemanager.projectIamAdmin) <code>•</code>|
