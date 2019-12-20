# Net Address Reservation Module

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Project where the addresses will be created. | <code title="">string</code> | ✓ | <code title=""></code> |
| *external_addresses* | Map of external address regions, keyed by name. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *global_addresses* | List of global addresses to create. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *internal_address_addresses* | Optional explicit addresses for internal addresses, keyed by name. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *internal_address_tiers* | Optional network tiers for internal addresses, keyed by name. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *internal_addresses* | Map of internal addresses to create, keyed by name. | <code title="map&#40;object&#40;&#123;&#10;region     &#61; string&#10;subnetwork &#61; string&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| external_addresses | None |  |
| global_addresses | None |  |
| internal_addresses | None |  |
<!-- END TFDOC -->