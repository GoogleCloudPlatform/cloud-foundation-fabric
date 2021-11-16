# Group data source

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| config | Configuration parameters from config.yaml | <code title=""></code> | ✓ |  |
| environments | Project environments | <code title="list&#40;string&#41;">list(string)</code> | ✓ |  |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| groups | All group IDs |  |
| monitoring_groups | Monitoring group IDs |  |
| serverless_groups | Serverless group IDs |  |
| shared_vpc_groups | Shared VPC group IDs |  |
<!-- END TFDOC -->
