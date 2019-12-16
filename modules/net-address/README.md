# Net Address Reservation Module

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required |
|---|---|:---: |:---:|
| project_id | Project where the addresses will be created. | `string` | ✓
| *external_addresses* | Map of external address regions, keyed by name. | `map(string)` | 
| *global_addresses* | List of global addresses to create. | `list(string)` | 
| *internal_address_addresses* | Optional explicit addresses for internal addresses, keyed by name. | `map(string)` | 
| *internal_address_tiers* | Optional network tiers for internal addresses, keyed by name. | `map(string)` | 
| *internal_addresses* | Map of internal addresses to create, keyed by name. | `map(object({...}))` | 

## Outputs

| name | description | sensitive |
|---|---|:---:|
| external_addresses | None |  |
| global_addresses | None |  |
| internal_addresses | None |  |
<!-- END TFDOC -->