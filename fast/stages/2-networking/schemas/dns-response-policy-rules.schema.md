# DNS Response Policy Rules Factory

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **project_id**: *string*
- **networks**: *array*
  - items: *string*
- **rules**: *object*
  <br>*additional properties: false*
  - **`^[a-z0-9-]+$`**: *object*
    <br>*additional properties: false*
    - **dns_name**: *string*
    - **behavior**: *string*
    - **local_data**: *object*
      <br>*additional properties: false*
      - **`^(?:A|AAAA|CAA|CNAME|DNSKEY|DS|HTTPS|IPSECVPNKEY|MX|NAPTR|NS|PTR|SOA|SPF|SRV|SSHFP|SVCB|TLSA|TXT)$`**: *object*
        <br>*additional properties: false*
        - **ttl**: *number*
        - **rrdatas**: *array*
          - items: *string*

## Definitions


