# CMEK on Cloud Storage and Compute Engine via centralized Cloud KMS

This sample creates a sample [Cloud KMS](https://cloud.google.com/kms?hl=it) configuration to be used with [Cloud Storage](https://cloud.google.com/storage/docs/encryption/using-customer-managed-keys) and [Copute Engine](https://cloud.google.com/compute/docs/disks/customer-managed-encryption).
Cloud KMS is deployed in a separate project to highlight the IAM binding needed and to mock a more real scenario where you usually have a project to manage keys across all your projects in one single place.

The sample has been purposefully kept simple so that it can be used as a basis for different and more complex configuration. This is the high level diagram:

![High-level diagram](diagram.png "High-level diagram")

## Managed resources and services

This sample creates several distinct groups of resources:

- projects
  - Cloud KMS project
  - Service Project configured for GCE instances and GCS buckets
- networking
  - VPC network
  - One subnet
  - Firewall rules for [SSH access via IAP](https://cloud.google.com/iap/docs/using-tcp-forwarding) and open communication within the VPC
- IAM
  - One service account for the GGE instance
- KMS
  - One key ring
  - One crypto key (Procection level: softwere) for Cloud Engine
  - One crypto key (Protection level: softwere) for Cloud Storage
- GCE
  - One instance encrypted with a CMEK Cryptokey hosted in Cloud KMS
- GCS
  - One bucket encrypted with a CMEK Cryptokey hosted in Cloud KMS

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| billing_account | Billing account id used as default for new projects. | <code title="">string</code> | ✓ |  |
| root_node | The resource name of the parent Folder or Organization. Must be of the form folders/folder_id or organizations/org_id. | <code title="">string</code> | ✓ |  |
| *location* | The location where resources will be deployed. | <code title="">string</code> |  | <code title="">europe</code> |
| *project_kms_name* | Name for the new KMS Project. | <code title="">string</code> |  | <code title="">my-project-kms-001</code> |
| *project_service_name* | Name for the new Service Project. | <code title="">string</code> |  | <code title="">my-project-service-001</code> |
| *region* | The region where resources will be deployed. | <code title="">string</code> |  | <code title="">europe-west1</code> |
| *vpc_ip_cidr_range* | Ip range used in the subnet deployef in the Service Project. | <code title="">string</code> |  | <code title="">10.0.0.0/20</code> |
| *vpc_name* | Name of the VPC created in the Service Project. | <code title="">string</code> |  | <code title="">local</code> |
| *vpc_subnet_name* | Name of the subnet created in the Service Project. | <code title="">string</code> |  | <code title="">subnet</code> |
| *zone* | The zone where resources will be deployed. | <code title="">string</code> |  | <code title="">europe-west1-b</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| bucket | GCS Bucket Cloud KMS crypto keys. |  |
| bucket_keys | GCS Bucket Cloud KMS crypto keys. |  |
| projects | Project ids. |  |
| vm | GCE VMs. |  |
| vm_keys | GCE VM Cloud KMS crypto keys. |  |
<!-- END TFDOC -->
