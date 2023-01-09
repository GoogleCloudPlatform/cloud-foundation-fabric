# Containerized MongoDB on Container Optimized OS

This module manages a `cloud-config` configuration that starts a containerized [MongoDB](https://www.mongodb.com/) service on Container Optimized OS, using the [official image](https://hub.docker.com/_/mongo).

The resulting `cloud-config` can be customized in a number of ways:

- a custom MongoDB configuration can be set using the `mongo_config` variable
- the container image can be changed via the `image` variable
- a data disk can be specified via the `mongo_data_disk` variable, the configuration will optionally format and mount it for container use
- a Secret Manager secret containing the root password can be passed to the container image
- a completely custom `cloud-config` can be passed in via the `cloud_config` variable, and additional template variables can be passed in via `config_variables`

The default instance configuration inserts a single iptables rule to allow traffic on the default MongoDB port.

Logging and monitoring are enabled via the [Google Cloud Logging agent](https://cloud.google.com/container-optimized-os/docs/how-to/logging) configured for the instance via the `google-logging-enabled` metadata property, and the [Node Problem Detector](https://cloud.google.com/container-optimized-os/docs/how-to/monitoring) service started by default on boot.

The module renders the generated cloud config in the `cloud_config` output, to be used in instances or instance templates via the `user-data` metadata.
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [admin_password_secret](variables.tf#L17) | Optional Secret Manager password for administration user. Leave null if no authentication is used. | <code>string</code> |  | <code>null</code> |
| [admin_username](variables.tf#L23) | Optional username for administration user. Leave null if no authentication is used. | <code>string</code> |  | <code>&#34;admin&#34;</code> |
| [artifact_registries](variables.tf#L29) | List of Artifact registry hostname to configure for Docker authentication. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;europe-west4-docker.pkg.dev&#34;, &#34;europe-docker.pkg.dev&#34;, &#34;us-docker.pkg.dev&#34;, &#34;asia-docker.pkg.dev&#34;&#93;</code> |
| [cloud_config](variables.tf#L35) | Cloud config template path. If null default will be used. | <code>string</code> |  | <code>null</code> |
| [config_variables](variables.tf#L41) | Additional variables used to render the cloud-config template. | <code>map&#40;any&#41;</code> |  | <code>&#123;&#125;</code> |
| [dns_zone](variables.tf#L47) | DNS zone for MongoDB SRV records. | <code>string</code> |  | <code>null</code> |
| [exporter_image](variables.tf#L53) | Prometheus metrics exporter image. | <code>string</code> |  | <code>&#34;percona&#47;mongodb_exporter:0.36&#34;</code> |
| [healthcheck_image](variables.tf#L59) | Health check container image. | <code>string</code> |  | <code>null</code> |
| [image](variables.tf#L65) | MongoDB container image. | <code>string</code> |  | <code>&#34;mongo:6.0&#34;</code> |
| [keyfile_secret](variables.tf#L71) | Secret Manager secret for keyfile used for authentication between replica set members. | <code>string</code> |  | <code>null</code> |
| [mongo_config](variables.tf#L77) | MongoDB configuration file content, if null container default will be used. | <code>string</code> |  | <code>null</code> |
| [mongo_data_disk](variables.tf#L83) | MongoDB data disk name in /dev/disk/by-id/ including the google- prefix. If null the boot disk will be used for data. | <code>string</code> |  | <code>null</code> |
| [mongo_port](variables.tf#L89) | Port to use for MongoDB. Defaults to 27017. | <code>number</code> |  | <code>27017</code> |
| [monitoring_image](variables.tf#L95) | Prometheus to Cloud Monitoring image. | <code>string</code> |  | <code>&#34;gke.gcr.io&#47;prometheus-engine&#47;prometheus:v2.35.0-gmp.2-gke.0&#34;</code> |
| [replica_set](variables.tf#L101) | Replica set name. | <code>string</code> |  | <code>null</code> |
| [startup_image](variables.tf#L107) | Startup container image. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [cloud_config](outputs.tf#L17) | Rendered cloud-config file to be passed as user-data instance metadata. |  |

<!-- END TFDOC -->
