# Hub and spoke with Network Virtual Appliance (NVA)

This dataset implements a hub-and-spoke topology using a set of Network Virtual Appliance (NVA) to control traffic flow between VPCs. This pattern is ideal for scenarios where you have compliance requirements to use a third-party firewall or security appliance, and [NGFW](https://cloud.google.com/firewall/docs/about-firewalls) (including NGFW Enteprise) doesn't "check the box".

The NVA acts as a central point of control, providing transitive routing between the spoke VPCs and allowing for the implementation of centralized security policies.

The following diagram illustrates the high-level design, and should be used as a reference for the following sections.

## VPC design

The design consists of four VPCs:

- **Hub VPC:** This VPC is intended to host centralized services and external connectivity.
- **Spoke VPCs (dev and prod):** These VPCs are used for different environments (e.g., development and production). They are isolated from each other by default, with all inter-VPC traffic routed through the NVA.
- **DMZ VPC:** This VPC is used for hosting resources that are exposed to the internet and acts as the egress point for the spoke VPCs. It also hosts VPN connectivity to on-premises.

## NVA Configuration

The core of this dataset is the Network Virtual Appliance (NVA), which is deployed in the `net-core-0` project. The NVA is configured as follows:

- **Multi-NIC Instances:** The NVA consists of multiple VM instances, each with multiple network interfaces (NICs). Each NIC is connected to a different VPC (hub, prod, dev, and dmz).
- **Internal Load Balancer (ILB):** An internal load balancer is used to provide high availability and distribute traffic across the NVA instances. The ILB has forwarding rules in the hub, prod, dev, and dmz VPCs.
- **Routing:** The NVA is responsible for routing traffic between the spoke VPCs. The operating system of the NVA instances must be configured to forward traffic between its NICs.

The NVA configuration is defined in the [`nvas/main.yaml`](./nvas/main.yaml) file. By default, the NVA factory allows for quick prototyping by deploying a set of very simple Linux instances that take care of routing traffic across the different NICs. The factory also allows the user to swap the automatically created instances with a production-grade set of NVAs, not provisioned by this codebase.

## Routing Configuration

The spoke VPCs and the DMZ VPC are configured to use the NVA as their default gateway. This is achieved by creating a default route in each VPC that points to the ILB of the NVA. The `hub` VPC has a specific route to the internet for `8.8.8.8/32`.

Here's an example from the `dmz` VPC configuration ([`vpcs/dmz/.config.yaml`](./vpcs/dmz/.config.yaml)):

```yaml
routes:
  gateway:
    dest_range: "0.0.0.0/0"
    priority: 100
    next_hop_type: ilb
    next_hop: $addresses:dmz/main
```

This configuration ensures that all traffic from the spoke VPCs is sent to the NVA for inspection and routing.

## VPN Connectivity

This dataset includes an HA VPN in the `dmz` VPC to connect to an on-premises network. The VPN uses the Cloud Router in the `dmz` VPC for dynamic routing via BGP. The VPN is defined in [`vpcs/dmz/vpns/onprem.yaml`](./vpcs/dmz/vpns/onprem.yaml)

## Internet egress

Internet egress for the spoke VPCs is handled by the NVA. The NIC connected to the `dmz` VPC is configured with `masquerade: true`, which enables Source Network Address Translation (SNAT) to CloudNAT. This allows instances in the spoke VPCs to access the internet through the NVA.

## Firewall

This dataset uses a combination of hierarchical firewall policies and VPC-level firewall rules to control traffic.

- **Hierarchical Firewall Policies:** These are defined in the [`firewall-policies`](./firewall-policies) directory and are used to enforce baseline security rules across the organization.
- **VPC Firewall Rules:** These are defined within each VPC's configuration and are used for more specific rules tailored to a particular VPC.

## DNS

This dataset implements a centralized DNS architecture similar to the other hub-and-spoke models. DNS is centralized in the hub project and shared with the spokes via DNS peering.
