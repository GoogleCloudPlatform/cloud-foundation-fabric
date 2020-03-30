# Containerized CoreDNS on Container Optimized OS

- [ ] test module
- [ ] add description and examples

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| *cloud_config* | Cloud config template path. If null default will be used. | <code title="">string</code> |  | <code title="">null</code> |
| *config_variables* | Additional variables used to render the cloud-config template. | <code title="map&#40;any&#41;">map(any)</code> |  | <code title="">{}</code> |
| *coredns_config* | CoreDNS configuration file content, if null default will be used. | <code title="">string</code> |  | <code title="">null</code> |
| *file_defaults* | Default owner and permissions for files. | <code title="object&#40;&#123;&#10;owner       &#61; string&#10;permissions &#61; string&#10;&#125;&#41;">object({...})</code> |  | <code title="&#123;&#10;owner       &#61; &#34;root&#34;&#10;permissions &#61; &#34;0644&#34;&#10;&#125;">...</code> |
| *files* | Map of extra files to create on the instance, path as key. Owner and permissions will use defaults if null. | <code title="map&#40;object&#40;&#123;&#10;content     &#61; string&#10;owner       &#61; string&#10;permissions &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *test_instance* | Test/development instance attributes, leave null to skip creation. | <code title="object&#40;&#123;&#10;project_id &#61; string&#10;zone       &#61; string&#10;name       &#61; string&#10;type &#61; string&#10;tags       &#61; list&#40;string&#41;&#10;metadata   &#61; map&#40;string&#41;&#10;network    &#61; string&#10;subnetwork &#61; string&#10;disks &#61; list&#40;object&#40;&#123;&#10;device_name &#61; string&#10;mode        &#61; string&#10;source      &#61; string&#10;&#125;&#41;&#41;&#10;&#125;&#41;">object({...})</code> |  | <code title="">null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cloud_config | Rendered cloud-config file to be passed as user-data instance metadata. |  |
| test_instance | Optional test instance name and address |  |
<!-- END TFDOC -->