# PSC Consumer

The module creates a consumer VPC and a Private Service Connect (PSC) endpoint, pointing to the PSC Service Attachment (SA) specified.
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L17) | Name of the resources created. | <code>string</code> | ✓ |  |
| [network](variables.tf#L22) | Consumer network id. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L27) | The ID of the project where this VPC will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L32) | Region where resources will be created. | <code>string</code> | ✓ |  |
| [sa_id](variables.tf#L37) | PSC producer service attachment id. | <code>string</code> | ✓ |  |
| [subnet](variables.tf#L42) | Subnetwork id where resources will be associated. | <code>string</code> | ✓ |  |

<!-- END TFDOC -->
