# VPC Serverless Connector

This FAST plugin adds centralized [Serverless VPC Access Connectors](https://cloud.google.com/vpc/docs/serverless-vpc-access) to network stages.

This plugin does not manage

- IAM bindings for the connectors, which should be added via the stage project-level variables
- firewall rules for the connectors, which should be added via the stage factory

The plugin only requires a specific configuration if the defaults it uses need to be changed:

- the connector-specific subnets default to the `10.255.255.0` range
- the machine type, number of instances and thoughput use the API defaults

To enable the plugin, simply copy or link its files in the networking stage.

<!-- TFDOC OPTS files:1 show_extra:1 -->
<!-- BEGIN TFDOC -->

## Files

| name | description | modules | resources |
|---|---|---|---|
| [local-serverless-connector-outputs.tf](./local-serverless-connector-outputs.tf) | Serverless Connector outputs. |  | <code>google_storage_bucket_object</code> · <code>local_file</code> |
| [local-serverless-connector-variables.tf](./local-serverless-connector-variables.tf) | Serverless Connector variables. |  |  |
| [local-serverless-connector.tf](./local-serverless-connector.tf) | Serverless Connector resources. | <code>net-vpc</code> | <code>google_vpc_access_connector</code> |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [serverless_connector_config](local-serverless-connector-variables.tf#L19) | VPC Access Serverless Connectors configuration. | <code title="object&#40;&#123;&#10;  dev-primary &#61; object&#40;&#123;&#10;    ip_cidr_range &#61; optional&#40;string, &#34;10.255.255.128&#47;28&#34;&#41;&#10;    machine_type  &#61; optional&#40;string&#41;&#10;    instances &#61; optional&#40;object&#40;&#123;&#10;      max &#61; optional&#40;number&#41;&#10;      min &#61; optional&#40;number&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    throughput &#61; optional&#40;object&#40;&#123;&#10;      max &#61; optional&#40;number&#41;&#10;      min &#61; optional&#40;number&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#10;  prod-primary &#61; object&#40;&#123;&#10;    ip_cidr_range &#61; optional&#40;string, &#34;10.255.255.0&#47;28&#34;&#41;&#10;    machine_type  &#61; optional&#40;string&#41;&#10;    instances &#61; optional&#40;object&#40;&#123;&#10;      max &#61; optional&#40;number&#41;&#10;      min &#61; optional&#40;number&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;    throughput &#61; optional&#40;object&#40;&#123;&#10;      max &#61; optional&#40;number&#41;&#10;      min &#61; optional&#40;number&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  dev-primary  &#61; &#123;&#125;&#10;  prod-primary &#61; &#123;&#125;&#10;&#125;">&#123;&#8230;&#125;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [plugin_sc_connectors](local-serverless-connector-outputs.tf#L47) | VPC Access Connectors. |  |  |

<!-- END TFDOC -->
