# Google Cloud Endpoints

This module allows simple management of ['Google Cloud Endpoints'](https://cloud.google.com/endpoints/) services. It supports creating ['OpenAPI'](https://cloud.google.com/endpoints/docs/openapi) or ['gRPC'](https://cloud.google.com/endpoints/docs/grpc/about-grpc) endpoints.

## Examples

### OpenAPI

```hcl
module "endpoint" {
  source         = "./modules/endpoints"
  project_id     = "my-project"
  service_name   = "YOUR-API.endpoints.YOUR-PROJECT-ID.cloud.goog"
  openapi_config = { "yaml_path" = "openapi.yaml" }
  iam = {
    "servicemanagement.serviceController" = [
      "serviceAccount:123456890-compute@developer.gserviceaccount.com"
    ]
  }
}
# tftest:skip
```

[Here](https://github.com/GoogleCloudPlatform/python-docs-samples/blob/master/endpoints/getting-started/openapi.yaml) you can find an example of an openapi.yaml file. Once created the endpoint, remember to activate the service at project level.

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| openapi_config | The configuration for an OpenAPI endopoint. Either this or grpc_config must be specified. | <code title="object&#40;&#123;&#10;yaml_path &#61; string&#10;&#125;&#41;">object({...})</code> | ✓ |  |
| service_name | The name of the service. Usually of the form '$apiname.endpoints.$projectid.cloud.goog'. | <code title="">string</code> | ✓ |  |
| *grpc_config* | The configuration for a gRPC enpoint. Either this or openapi_config must be specified. | <code title="object&#40;&#123;&#10;yaml_path          &#61; string&#10;protoc_output_path &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |
| *iam* | IAM bindings for topic in {ROLE => [MEMBERS]} format. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *project_id* | The project ID that the service belongs to. | <code title="">string</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| endpoints | A list of Endpoint objects. |  |
| endpoints_service | The Endpoint service resource. |  |
| service_name | The name of the service.. |  |
<!-- END TFDOC -->
