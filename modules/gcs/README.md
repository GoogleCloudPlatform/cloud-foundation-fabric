# Google Cloud Storage Module

## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| names | Bucket name suffixes. | list | ✓
| prefix | Prefix used to generate the bucket name. | string | ✓
| project_id | Bucket project id. | string | ✓
| *admins* | IAM-style members who will be granted roles/storage.admin on all buckets. | list | 
| *bucket_admins* | Map of lowercase unprefixed name => comma-delimited IAM-style bucket storage admins. | map | 
| *bucket_creators* | Map of lowercase unprefixed name => comma-delimited IAM-style per-bucket object creators. | map | 
| *bucket_hmackey_admins* | Map of lowercase unprefixed name => comma-delimited IAM-style per-bucket hmacKey admins. | map | 
| *bucket_object_admins* | Map of lowercase unprefixed name => comma-delimited IAM-style per-bucket object admins. | map | 
| *bucket_policy_only* | Disable ad-hoc ACLs on specified buckets. Defaults to true. Map of lowercase unprefixed name => boolean | map | 
| *bucket_viewers* | Map of lowercase unprefixed name => comma-delimited IAM-style per-bucket object viewers. | map | 
| *creators* | IAM-style members who will be granted roles/storage.objectCreators on all buckets. | list | 
| *force_destroy* | Optional map of lowercase unprefixed name => boolean, defaults to false. | map | 
| *hmackey_admins* | IAM-style members who will be granted roles/storage.hmacKeyAdmin on all buckets. | list | 
| *labels* | Labels to be attached to the buckets | map | 
| *location* | Bucket location. | string | 
| *object_admins* | IAM-style members who will be granted roles/storage.objectAdmin on all buckets. | list | 
| *set_admin_roles* | Grant roles/storage.admin role to storage_admins and bucket_storage_admins. | bool | 
| *set_creator_roles* | Grant roles/storage.objectCreator role to creators and bucket_creators. | bool | 
| *set_hmackey_admin_roles* | Grant roles/storage.hmacKeyAdmin role to storage_admins and bucket_storage_admins. | bool | 
| *set_object_admin_roles* | Grant roles/storage.objectAdmin role to admins and bucket_admins. | bool | 
| *set_viewer_roles* | Grant roles/storage.objectViewer role to viewers and bucket_viewers. | bool | 
| *storage_class* | Bucket storage class. | string | 
| *versioning* | Optional map of lowercase unprefixed name => boolean, defaults to false. | map | 
| *viewers* | IAM-style members who will be granted roles/storage.objectViewer on all buckets. | list | 

## Outputs

| name | description |
|---|---|
| bucket | Bucket resource (for single use). |
| buckets | Bucket resources. |
| name | Bucket name (for single use). |
| names | Bucket names. |
| names_list | List of bucket names. |
| url | Bucket URL (for single use). |
| urls | Bucket URLs. |
| urls_list | List of bucket URLs. |
