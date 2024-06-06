# Google Cloud VMWare Engine Monitoring Module

The module sets up Monitoring for Google Cloud VMWare Engine Private Clouds.

Infrastructure monitoring and logging for GCVE is commonly set up using a [standalone Bindplane agent](https://cloud.google.com/vmware-engine/docs/environment/howto-cloud-monitoring-standalone). This module deploys the bindplane agent using a Managed Instance Group to accept metrics and Syslog logs from VMware vCenter and forward them to Cloud Monitoring and Cloud Logging. To forward syslog messages, please refer to the following documentation on [how to configure a private cloud for syslog forwarding](https://cloud.google.com/vmware-engine/docs/environment/howto-forward-syslog).

This module deploys and configures the following resources:
 * Service Account for Bindplane Agent with permissions to write logs/metrics and access Secret Manager
 * A firewall rule to allow a healthcheck of port TCP 5142 to check whether the agent runs correctly.
 * Default Monitoring Dashboards for GCVE
 * A GCE VM template using Debian 11 for the bindplane agent
 * A GCE Managed Instance Group for the bindplane agent
 * Secret Manager secrets:
    * vCenter Username
    * vCenter Password
    * vCenter FQDN

Note that to complete the Monitoring setup you need to configure vCenter to send traffic to the Bindplane agent which listens by default on port TCP 5142.

<!-- BEGIN TOC -->
- [Basic Monitoring setup with default settings](#basic-monitoring-setup-with-default-settings)
<!-- END TOC -->

## Basic Monitoring setup with default settings

```hcl
module "gcve-monitoring" {
  source     = "./fabric/modules/gcve-private-cloud"
  project_id = "gcve-test-project"

  vm_mon_zone             = "europe-west1-b"
  subnetwork              = "prod-default-ew1"
  gcve_region             = "europe-west1"
  create_dashboards       = "true"
  network_project_id      = "test-prj-gcve-01"
  network_self_link       = "projects/test-prj-gcve-01/global/networks/default"
}
```


```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [gcve_region](variables.tf#L23) | Region where the Private Cloud is deployed. | <code>string</code> | ✓ |  |
| [network_project_id](variables.tf#L40) | Project ID of shared VPC. | <code>string</code> | ✓ |  |
| [network_self_link](variables.tf#L45) | Self link of VPC in which Monitoring instance is deployed. | <code>string</code> | ✓ |  |
| [project_id](variables.tf#L60) | Project id of existing or created project. | <code>string</code> | ✓ |  |
| [subnetwork](variables.tf#L89) | Subnetwork where the VM will be deployed to. | <code>string</code> | ✓ |  |
| [vm_mon_zone](variables.tf#L106) | GCP zone where GCE VM will be deployed. | <code>string</code> | ✓ |  |
| [create_dashboards](variables.tf#L17) | Define if sample GCVE monitoring dashboards should be installed. | <code>bool</code> |  | <code>true</code> |
| [initial_delay_sec](variables.tf#L28) | How long to delay checking for healthcheck upon initialization. | <code>number</code> |  | <code>180</code> |
| [monitoring_image](variables.tf#L34) | Resource URI for OS image used to deploy monitoring agent. | <code>string</code> |  | <code>&#34;projects&#47;debian-cloud&#47;global&#47;images&#47;family&#47;debian-11&#34;</code> |
| [project_create](variables.tf#L50) | Project configuration for newly created project. Leave null to use existing project. Project creation forces VPC and cluster creation. | <code title="object&#40;&#123;&#10;  billing_account &#61; string&#10;  parent          &#61; optional&#40;string&#41;&#10;  shared_vpc_host &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [sa_gcve_monitoring](variables.tf#L65) | Service account for GCVE monitoring agent. | <code>string</code> |  | <code>&#34;gcve-mon-sa&#34;</code> |
| [secret_vsphere_password](variables.tf#L71) | The secret name containing the password for the vCenter admin user. | <code>string</code> |  | <code>&#34;gcve-mon-vsphere-password&#34;</code> |
| [secret_vsphere_server](variables.tf#L77) | The secret name conatining the FQDN of the vSphere vCenter server. | <code>string</code> |  | <code>&#34;gcve-mon-vsphere-server&#34;</code> |
| [secret_vsphere_user](variables.tf#L83) | The secret name containing the user for the vCenter server. Must be an admin user. | <code>string</code> |  | <code>&#34;gcve-mon-vsphere-user&#34;</code> |
| [vm_mon_name](variables.tf#L94) | GCE VM name where GCVE monitoring agent will run. | <code>string</code> |  | <code>&#34;bp-agent&#34;</code> |
| [vm_mon_type](variables.tf#L100) | GCE VM machine type. | <code>string</code> |  | <code>&#34;e2-small&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [gcve-mon-firewall](outputs.tf#L17) | Ingress rule to allow GCVE Syslog traffic. |  |
| [gcve-mon-mig](outputs.tf#L22) | Managed Instance Group for GCVE Monitoring. |  |
| [gcve-mon-permissions](outputs.tf#L27) | IAM roles of Service Account for GCVE Monitoring. |  |
| [gcve-mon-sa](outputs.tf#L32) | Service Account for GCVE Monitoring. |  |
<!-- END TFDOC -->
