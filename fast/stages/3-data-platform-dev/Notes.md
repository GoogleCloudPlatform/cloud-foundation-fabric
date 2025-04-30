# Notes

- [ ] implement tag substitution for product-level IAM conditions
- [x] allow all four network configurations for Composer
- [x] add `automation` block to data domains and products
- [x] move processing serivce account and IAM from product code to YAML
- [ ] expose IAM for "exposure" buckets and datasets using the format below

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
