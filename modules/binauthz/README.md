# Google Cloud Binary Authorization Module

This module simplifies the creation of a Binary Authorization policy, attestors and attestor IAM bindings.

## Example

### Binary Authorization

```hcl
module "binauthz" {
  source     = "./fabric/modules/binauthz"
  project_id = "my_project"
  default_admission_rule = {
    evaluation_mode  = "ALWAYS_DENY"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    attestors        = null
  }
  cluster_admission_rules = {
    "europe-west1-c.cluster" = {
      evaluation_mode  = "REQUIRE_ATTESTATION"
      enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
      attestors        = ["test"]
    }
  }
  attestors_config = {
    "test" : {
      note_reference = null
      pgp_public_keys = [
        <<EOT
            mQENBFtP0doBCADF+joTiXWKVuP8kJt3fgpBSjT9h8ezMfKA4aXZctYLx5wslWQl
            bB7Iu2ezkECNzoEeU7WxUe8a61pMCh9cisS9H5mB2K2uM4Jnf8tgFeXn3akJDVo0
            oR1IC+Dp9mXbRSK3MAvKkOwWlG99sx3uEdvmeBRHBOO+grchLx24EThXFOyP9Fk6
            V39j6xMjw4aggLD15B4V0v9JqBDdJiIYFzszZDL6pJwZrzcP0z8JO4rTZd+f64bD
            Mpj52j/pQfA8lZHOaAgb1OrthLdMrBAjoDjArV4Ek7vSbrcgYWcI6BhsQrFoxKdX
            83TZKai55ZCfCLIskwUIzA1NLVwyzCS+fSN/ABEBAAG0KCJUZXN0IEF0dGVzdG9y
            IiA8ZGFuYWhvZmZtYW5AZ29vZ2xlLmNvbT6JAU4EEwEIADgWIQRfWkqHt6hpTA1L
            uY060eeM4dc66AUCW0/R2gIbLwULCQgHAgYVCgkICwIEFgIDAQIeAQIXgAAKCRA6
            0eeM4dc66HdpCAC4ot3b0OyxPb0Ip+WT2U0PbpTBPJklesuwpIrM4Lh0N+1nVRLC
            51WSmVbM8BiAFhLbN9LpdHhds1kUrHF7+wWAjdR8sqAj9otc6HGRM/3qfa2qgh+U
            WTEk/3us/rYSi7T7TkMuutRMIa1IkR13uKiW56csEMnbOQpn9rDqwIr5R8nlZP5h
            MAU9vdm1DIv567meMqTaVZgR3w7bck2P49AO8lO5ERFpVkErtu/98y+rUy9d789l
            +OPuS1NGnxI1YKsNaWJF4uJVuvQuZ1twrhCbGNtVorO2U12+cEq+YtUxj7kmdOC1
            qoIRW6y0+UlAc+MbqfL0ziHDOAmcqz1GnROg
            =6Bvm
            EOT
      ]
      pkix_public_keys = null
      iam = {
        "roles/viewer" = ["user:user1@my_org.com"]
      }
    }
  }
}
# tftest modules=1 resources=4

```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L62) | Project ID. | <code>string</code> | ✓ |  |
| [admission_whitelist_patterns](variables.tf#L17) | An image name pattern to allowlist. | <code>list&#40;string&#41;</code> |  | <code>null</code> |
| [attestors_config](variables.tf#L23) | Attestors configuration. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [cluster_admission_rules](variables.tf#L38) | Admission rules. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>null</code> |
| [default_admission_rule](variables.tf#L48) | Default admission rule. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#8230;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [attestors](outputs.tf#L17) | Attestors. |  |
| [id](outputs.tf#L25) | Fully qualified Binary Authorization policy ID. |  |
| [notes](outputs.tf#L30) | Notes. |  |
<!-- END TFDOC -->
