# Google Cloud IoT Core Module

This module allows setting up Cloud IoT Core Registry, register devices and configure Pub/Sub topics

## Example

```
module "iot-platform" {
  source     = "./iot-core"
  project_id = "my-project"
  region = "my-region"
  devices = {
      device_1 = "device_certs/rsa_cert1.pem"
      device_2 = "device_certs/rsa_cert2.pem"
  }
}
```


<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Project used for resources. | <code title="">string</code> | ✓ |  |
| *region* | Region used to deploy | <code title="">string</code> | ✓ |  |
| *devices* | List of devices to be registered, using the format device-id -- device-cert | <code title="">map(list(string))</code> |  | <code title="">{}</code> |


## Outputs

| name | description | sensitive |
|---|---|:---:|
| tbc | tbc |  |
<!-- END TFDOC -->

