# TODO

- Support different NCC topologies
- Move folders creation to 0-org-setup
- Use VPC-reuse to manage the creation of routes - depends on ILBs for NVAs.
- Re-implement DNS and Firewall policies factories
  - Use a .config file to configure the factory, then consume the module's factory
- Re-implement UIG creation on NVA factory, to allow attaching arbitrary instances
  - Test creation
