# TODO / Brainstorm

- Automatically generated names should use resource name, not key
- VPN Factory doesn't currently allow passing an arbitrary local vpn gateway
  - ... do we care?
- Automatically created routers are not added to context and are not reusable
  - Not trivial to solve because of dependencies - e.g. vpn-ha has a dependency on the router context to be ready, but can also automatically manage the creation of a router itself
  - ... do we care?
- s/$gateways/$vpn_gateways/g
- Support different NCC topologies
- DNS response policies: project key is currently inferred from filename. Ick.
