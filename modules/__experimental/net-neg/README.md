# Network Endpoint Group Module

This modules allows creating zonal network endpoint groups.

Note: this module will integrated into a general-purpose load balancing module in the future.

## Example
```hcl
module "neg" {
  source     = "./modules/net-neg"
  project_id = "myproject"
  name       = "myneg"
  network    = module.vpc.self_link
  subnetwork = module.vpc.subnet_self_links["europe-west1/default"]
  zone       = "europe-west1-b"
  endpoints = [
    for instance in module.vm.instances :
    {
      instance   = instance.name
      port       = 80
      ip_address = instance.network_interface[0].network_ip
    }
  ]
}
```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| endpoints | List of (instance, port, address) of the NEG | <code title="list&#40;object&#40;&#123;&#10;instance   &#61; string&#10;port       &#61; number&#10;ip_address &#61; string&#10;&#125;&#41;&#41;">list(object({...}))</code> | ✓ |  |
| name | NEG name | <code title="">string</code> | ✓ |  |
| network | Name or self link of the VPC used for the NEG. Use the self link for Shared VPC. | <code title="">string</code> | ✓ |  |
| project_id | NEG project id. | <code title="">string</code> | ✓ |  |
| subnetwork | VPC subnetwork name or self link. | <code title="">string</code> | ✓ |  |
| zone | NEG zone | <code title="">string</code> | ✓ |  |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| id | Network endpoint group ID |  |
| self_lnk | Network endpoint group self link |  |
| size | Size of the network endpoint group |  |
<!-- END TFDOC -->
