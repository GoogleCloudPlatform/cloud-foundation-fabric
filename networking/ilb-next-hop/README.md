# Internal Load Balancer for Gateways

This example allows testing [ILB as next hop](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview) using simple Linux gateway VMS between two VPCs, to emulate virtual appliances. An optional additional ILB can be enabled to test multiple load balancer configurations and hashing.

The following diagram shows the resources created by this example

![High-level diagram](diagram.png "High-level diagram")

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Existing project id. | <code title="">string</code> | ✓ |  |
| *ilb_right_enable* | Route right to left traffic through ILB. | <code title="">bool</code> |  | <code title="">false</code> |
| *ilb_session_affinity* | Session affinity configuration for ILBs. | <code title="">string</code> |  | <code title="">CLIENT_IP</code> |
| *ip_ranges* | IP CIDR ranges used for VPC subnets. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="&#123;&#10;left  &#61; &#34;10.0.0.0&#47;24&#34;&#10;right &#61; &#34;10.0.1.0&#47;24&#34;&#10;&#125;">...</code> |
| *prefix* | Prefix used for resource names. | <code title="">string</code> |  | <code title="">ilb-test</code> |
| *project_create* | Create project instead of using an existing one. | <code title="">bool</code> |  | <code title="">false</code> |
| *region* | Region used for resources. | <code title="">string</code> |  | <code title="">europe-west1</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| addresses | Internal addresses of created VMS. |  |
<!-- END TFDOC -->
