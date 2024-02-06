## Environment setup
- ✓ Set up Terraform: done
- ✓ Store Terraform state: skipped
- ✓ Create a metrics scope using Terraform: TBD
- ? Set up Helm: depends on the workload, not the cluster setup
- ✓ Set up Artifact Registry: done, through virtual respositories
- ⨯ Set up Binary Authorization: this is more a CI/CD topic, which is out-of-scope for blueprints

## Cluster configuration
- ✓ Choose a mode of operation: we deploy autopilot by default, but standard is also supported
- ✓ Isolate your cluster: we deploy a private cluster, with private control plane
- ⨯ Configure backup for GKE: skipped
- ? Use Container-Optimized OS node images: depends on the workload, not the cluster setup
- ✓ Enable node auto-provisioning: automatically managed by autopilot (confirm)
- ✓ Separate kube-system Pods: automatically managed by autopilot (confirm)


## Security
- ✓ Use the security posture dashboard: enabled by default in new clusters
-   Use group authentication: review if needed
- ⨯ Use RBAC to restrict access to cluster resources: skipped
- ✓ Enable Shielded GKE Nodes: done by autopilot
- ✓ Enable Workload Identity: done by autopilot
- ⨯ Enable security bulletin notifications: skipped
- ✓ Use least privilege Google service accounts: done
- ✓ Restrict network access to the control plane and nodes: done
-   Restrict access to cluster API discovery: review if needed
- ? ~~Use namespaces to restrict access to cluster resources~~: done by the workloads

## Networking
- ✓ Create a custom mode VPC: if we deploy the VPC, we use a custom vpc with a single subnet
- ✓ Create a proxy-only subnet: TBD
- ✓ Configure Shared VPC: By default we deploy a new VPC within the project, but Shared VPC can be used when the blueprint handles project creation.
- ⨯ Connect the cluster's VPC network to an on-premises network: skipped, out of scope for a blueprint
- ✓ Enable Cloud NAT: not needed for redis but TBD as optional
- ✓ Configure Cloud DNS for GKE: TBD
- ✓ Configure NodeLocal DNSCache: TBD
- ⨯ Create firewall rules: skipped

## Multitenancy
For simplicity, multi-tenancy is not used in the jumpstart blueprints

## Monitoring
- ⨯ Configure GKE alert policies: out of scope for a blueprint
- ✓ Enable Google Cloud Managed Service for Prometheus: done by autopilot
- ✓ Configure control plane metrics: done
- ⨯ Enable metrics packages: skipped


## Maintnance
- ⨯ Create environments: out of scope for a blueprint
- ⨯ Subscribe to Pub/Sub events: out of scope for a blueprint
- ✓ Enroll in release channels: TBD
- ✓ Configure maintenance windows: TBD
- ⨯ Set Compute Engine quotas: out of scope for a blueprint
- ✓ Configure cost controls: TBD
- ⨯ Configure billing alerts: out of scope for a blueprint
