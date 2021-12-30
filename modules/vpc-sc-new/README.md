# VPC Service Controls

## TODO

- [ ] implement support for the  `google_access_context_manager_gcp_user_access_binding` resource


<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| access_levels | Map of access levels in name => [conditions] format. | <code title="map&#40;object&#40;&#123;&#10;  combining_function &#61; string&#10;  conditions &#61; list&#40;object&#40;&#123;&#10;    device_policy &#61; object&#40;&#123;&#10;      require_screen_lock              &#61; bool&#10;      allowed_encryption_statuses      &#61; list&#40;string&#41;&#10;      allowed_device_management_levels &#61; list&#40;string&#41;&#10;      os_constraints &#61; list&#40;object&#40;&#123;&#10;        minimum_version            &#61; string&#10;        os_type                    &#61; string&#10;        require_verified_chrome_os &#61; bool&#10;      &#125;&#41;&#41;&#10;      require_admin_approval &#61; bool&#10;      require_corp_owned     &#61; bool&#10;    &#125;&#41;&#10;    ip_subnetworks         &#61; list&#40;string&#41;&#10;    members                &#61; list&#40;string&#41;&#10;    negate                 &#61; bool&#10;    regions                &#61; list&#40;string&#41;&#10;    required_access_levels &#61; list&#40;string&#41;&#10;  &#125;&#41;&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| access_policy | Access Policy name, leave null to use auto-created one. | <code>string</code> |  | <code>null</code> |
| access_policy_create | Access Policy configuration, fill in to create. Parent is in 'organizations/123456' format. | <code title="object&#40;&#123;&#10;  parent &#61; string&#10;  title  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| service_perimeters | Service perimeters. | <code title="map&#40;object&#40;&#123;&#10;  spec &#61; object&#40;&#123;&#10;    access_levels       &#61; list&#40;string&#41;&#10;    resources           &#61; list&#40;string&#41;&#10;    restricted_services &#61; list&#40;string&#41;&#10;    egress_policies &#61; list&#40;object&#40;&#123;&#10;      egress_from &#61; object&#40;&#123;&#10;        identity_type &#61; string&#10;        identities    &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;      egress_to &#61; object&#40;&#123;&#10;        operations &#61; list&#40;object&#40;&#123;&#10;          method_selectors &#61; list&#40;string&#41;&#10;          service_name     &#61; string&#10;        &#125;&#41;&#41;&#10;        resources &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;&#10;    ingress_policies &#61; list&#40;object&#40;&#123;&#10;      ingress_from &#61; object&#40;&#123;&#10;        identity_type        &#61; string&#10;        identities           &#61; list&#40;string&#41;&#10;        source_access_levels &#61; list&#40;string&#41;&#10;        source_resources     &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;      ingress_to &#61; object&#40;&#123;&#10;        operations &#61; list&#40;object&#40;&#123;&#10;          method_selectors &#61; list&#40;string&#41;&#10;          service_name     &#61; string&#10;        &#125;&#41;&#41;&#10;        resources &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;&#10;    vpc_accessible_services &#61; object&#40;&#123;&#10;      allowed_services   &#61; list&#40;string&#41;&#10;      enable_restriction &#61; bool&#10;    &#125;&#41;&#10;  &#125;&#41;&#10;  status &#61; object&#40;&#123;&#10;    access_levels       &#61; list&#40;string&#41;&#10;    resources           &#61; list&#40;string&#41;&#10;    restricted_services &#61; list&#40;string&#41;&#10;    egress_policies &#61; list&#40;object&#40;&#123;&#10;      egress_from &#61; object&#40;&#123;&#10;        identity_type &#61; string&#10;        identities    &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;      egress_to &#61; object&#40;&#123;&#10;        operations &#61; list&#40;object&#40;&#123;&#10;          method_selectors &#61; list&#40;string&#41;&#10;          service_name     &#61; string&#10;        &#125;&#41;&#41;&#10;        resources &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;&#10;    ingress_policies &#61; list&#40;object&#40;&#123;&#10;      ingress_from &#61; object&#40;&#123;&#10;        identity_type        &#61; string&#10;        identities           &#61; list&#40;string&#41;&#10;        source_access_levels &#61; list&#40;string&#41;&#10;        source_resources     &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;      ingress_to &#61; object&#40;&#123;&#10;        operations &#61; list&#40;object&#40;&#123;&#10;          method_selectors &#61; list&#40;string&#41;&#10;          service_name     &#61; string&#10;        &#125;&#41;&#41;&#10;        resources &#61; list&#40;string&#41;&#10;      &#125;&#41;&#10;    &#125;&#41;&#41;&#10;    vpc_accessible_services &#61; object&#40;&#123;&#10;      allowed_services   &#61; list&#40;string&#41;&#10;      enable_restriction &#61; bool&#10;    &#125;&#41;&#10;  &#125;&#41;&#10;  perimeter_type            &#61; string&#10;  use_explicit_dry_run_spec &#61; bool&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| access_levels | Access level resources. |  |
| access_policy | Access policy resource, if autocreated. |  |
| access_policy_name | Access policy name. |  |
| service_perimeters | service perimeter resources. |  |

<!-- END TFDOC -->

