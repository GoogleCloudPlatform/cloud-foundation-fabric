# Packer example

The following Packer example builds Compute Engine image based on Centos 8 Linux.
The image is provisioned with a sample shell scripts to update OS packages and install HTTP server.

The example uses following GCP features:

* [service account impersonation](https://cloud.google.com/iam/docs/impersonating-service-accounts)
* [Identity-Aware Proxy](https://cloud.google.com/iap/docs/using-tcp-forwarding) tunnel

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| builder_sa | Image builder's service account email. | <code title="">string</code> | ✓ |  |
| compute_sa | Temporary's VM service account email. | <code title="">string</code> | ✓ |  |
| compute_subnetwork | Name of a VPC subnetwork for temporary VM instance. | <code title="">string</code> | ✓ |  |
| compute_zone | Compute Engine zone to run temporary VM instance. | <code title="">string</code> | ✓ |  |
| project_id | Project id that references existing GCP project. | <code title="">string</code> | ✓ |  |
| *use_iap* | Indicates to use IAP tunnel for communication with temporary VM instance. | <code title="">bool</code> |  | <code title="">true</code> |

<!-- END TFDOC -->