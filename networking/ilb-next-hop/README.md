# Internal Load Balancer as Next Hop

This example bootstraps a minimal infrastructure for testing [ILB as next hop](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview),  using simple Linux gateway VMS between two VPCs to emulate virtual appliances.

The following diagram shows the resources created by this example

![High-level diagram](diagram.png "High-level diagram")

Two ILBs are configured on the primary and secondary interfaces of gateway VMs with active health checks, but only a single one is used as next hop by default to simplify testing. The second (right-side) VPC has default routes that point to the gateway VMs, to also use the right-side ILB as next hop set the `ilb_right_enable` variable to `true`.

## Testing

This setup can be used to test and verify new ILB features like [forwards all protocols on ILB as next hops](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview#all-traffic) and [symmetric hashing](https://cloud.google.com/load-balancing/docs/internal/ilb-next-hop-overview#symmetric-hashing), using simple `curl` and `ping` tests on clients. To make this practical, test VMs on both VPCs have `nginx` pre-installed and active on port 80.

On the gateways, `iftop` and `tcpdump` are installed by default to quickly monitor traffic passing forwarded across VPCs.

Session affinity on the ILB backend services can be changed using `gcloud compute backend-services update` on each of the ILBs, or by setting the `ilb_session_affinity` variable to update both ILBs.

Simple `/root/start.sh` and `/root/stop.sh` scripts are pre-installed on both gateways to configure `iptables` so that health check requests are rejected and re-enabled, to quickly simulate removing instances from the ILB backends.

Some scenarios to test:

- short-lived connections with session affinity set to the default of `NONE`, then to `CLIENT_IP`
- long-lived connections, failing health checks on the active gateway while the connection is active

### Useful commands

Basic commands to SSH to VMs and monitor backend health are provided in the Terraform outputs, and they already match input variables so that names, zones, etc. are correct. Other testing commands are provided below, adjust names to match your setup.

Create a large file on a destination VM (eg `ilb-test-vm-right-1`) to test long-running connections.

```bash
dd if=/dev/zero of=/var/www/html/test.txt bs=10M count=100 status=progress
```

Run curl from a source VM (eg `ilb-test-vm-left-1`) to send requests to a destination VM artifically slowing traffic.

```bash
curl -0 --output /dev/null --limit-rate 10k 10.0.1.3/test.txt
```

Monitor traffic from a source VM (eg `ilb-test-vm-left-1`) on the gateways.

```bash
iftop -n -F 10.0.0.3/32
```

Poll summary health status for a backend.

```bash
watch '\
  gcloud compute backend-services get-health ilb-test-ilb-right \
    --region europe-west1 \
    --flatten status.healthStatus \
    --format "value(status.healthStatus.ipAddress, status.healthStatus.healthState)" \
'
```

A sample testing session using `tmux`:

<a href="https://raw.githubusercontent.com/terraform-google-modules/cloud-foundation-fabric/master/networking/ilb-next-hop/test_session.png" title="Test session screenshot"><img src="./test_session.png" width="640px" alt="Test session screenshot"></img>

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Existing project id. | <code title="">string</code> | ✓ |  |
| *ilb_right_enable* | Route right to left traffic through ILB. | <code title="">bool</code> |  | <code title="">false</code> |
| *ilb_session_affinity* | Session affinity configuration for ILBs. | <code title="">string</code> |  | <code title="">CLIENT_IP</code> |
| *ip_ranges* | IP CIDR ranges used for VPC subnets. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="&#123;&#10;left  &#61; &#34;10.0.0.0&#47;24&#34;&#10;right &#61; &#34;10.0.1.0&#47;24&#34;&#10;&#125;">...</code> |
| *prefix* | Prefix used for resource names. | <code title="">string</code> |  | <code title="">ilb-test</code> |
| *project_create* | Create project instead of using an existing one. | <code title="">bool</code> |  | <code title="">false</code> |
| *region* | Region used for resources. | <code title="">string</code> |  | <code title="">europe-west1</code> |
| *zones* | Zone suffixes used for instances. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">["b", "c"]</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| addresses | IP addresses. |  |
| backend_health_left | Command-line health status for left ILB backends. |  |
| backend_health_right | Command-line health status for right ILB backends. |  |
| ssh_gw | Command-line login to gateway VMs. |  |
| ssh_vm_left | Command-line login to left VMs. |  |
| ssh_vm_right | Command-line login to right VMs. |  |
<!-- END TFDOC -->
