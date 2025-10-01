# TODO / Brainstorm

- Automatically generated names should use resource name, not key
- Should keys contain the full path? e.g. data/lab/vpcs/hub vs hub or data/lab/vpcs/hub-vpn/to-prod vs hub-vpn/to-prod
  - The latter allows easier distribution of recipes and folder refactoring without updating keys
  - The latter is also aligned with other keys, e.g. projects
- VPN Factory doesn't currently allow passing an arbitrary local vpn gateway
  - ... do we care?
- Automatically created routers are not added to context and are not reusable
  - Not trivial to solve because of dependencies - e.g. vpn-ha has a dependency on the router context to be ready, but can also automatically manage the creation of a router itself
  - ... do we care?
