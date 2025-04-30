# Notes

- [x] implement tag substitution for product-level IAM conditions
- [x] allow all four network configurations for Composer
- [x] add `automation` block to data domains and products
- [x] allow project and exposure-level interpolation for automation sa
- [x] move processing serivce account and IAM from product code to YAML
- [x] expose IAM for "exposure" buckets and datasets using the format below
- [ ] output tfvars for the stage
- [ ] output provider files for the products
- [x] context replacements in shared vpc service project IAM and project id
- [x] automation block for data domains
- [x] tag context in data domain folder and project
- [ ] resman: interpolate stage sa using slash

```yaml
exposure_layer:
  bigquery:
    iam:
      roles/foo:
        - user:foo@example.com
    datasets:
      exposed_ew8:
        location: europe-west8
  storage:
    iam:
      roles/foo:
        - user:foo@example.com
    buckets:
      exposed-ew8:
        location: europe-west8
```
