# Notes

- [x] get projects
  `get_monitored_projects_list`
- [ ] set monitoring interval
  `monitoring_interval`
- [ ] read metrics and limits from yaml and create descriptors
  `metrics.create_metrics`
- [x] get project quota
  `limits.get_quota_project_limit`
- [x] get firewall rules from CAI
  `vpc_firewalls.get_firewalls_dict`
- [x] get firewall policies from CAI
  `firewall_policies.get_firewall_policies_dict`
- [x] get instances
  `instances.get_gce_instance_dict`
- [x] get forwarding rules for L4 ILB
  `ilb_fwrules.get_forwarding_rules_dict`
- [x] get forwarding rules for L7 ILB
  `ilb_fwrules.get_forwarding_rules_dict`
- [x] get subnets and secondary ranges
  `networks.get_subnet_ranges_dict`
- [x] get static routes
  `routes.get_static_routes_dict`
- [x] get dynamic routes
  routes.get_dynamic_routes
  - get routers
    `routers.get_routers`
  - get networks
    `networks.get_networks`
  - get router status
    `get_routes_for_network`
    `get_routes_for_router`
- [x] get and store subnet metrics
  `subnets.get_subnets`
  - get subnets
    `get_all_subnets`
  - calculate subnet utilization
    `compute_subnet_utilization`
    - [x] get instances
      `compute_subnet_utilization_vms`
    - [x] get forwarding rules
      `compute_subnet_utilization_ilbs`
    - [x] get addresses
      `compute_subnet_utilization_addresses`
    - [ ] get redis instances
      `compute_subnet_utilization_redis`
  - store metrics
- [x]calculate and store firewall rule metrics
  `vpc_firewalls.get_firewalls_data`
- [x] calculate and store firewall policy metrics
  `firewall_policies.get_firewal_policies_data`
- [x] calculate and store instance per network metrics
  `instances.get_gce_instances_data`
- [x] calculate and store L4 forwarding rule metrics
  `ilb_fwrules.get_forwarding_rules_data`
- [x] calculate and store L7 forwarding rule metrics
  `ilb_fwrules.get_forwarding_rules_data`
- [x] calculate and store static routes metrics
  `routes.get_static_routes_data`
- [x] calculate and store peering metrics
  `peerings.get_vpc_peering_data`
- [ ] calculate and store peering group metrics
  `metrics.get_pgg_data`
  `routes.get_routes_ppg`
- [ ] write buffered timeseries
  `metrics.flush_series_buffer`
- [x] add per-network and per-project hidden quota override
  - [x] implement a custom quota override mechanism
  - [x] use it in timeseries plugins
