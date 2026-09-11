# Secure Source Manager and Cloud Build CI/CD

This setup brings up a private Secure Source Manager instance and the Cloud Build machinery that runs pipelines from its repositories: the Private Service Connect access path to the instance, a Cloud Build private worker pool, one repository-level service account per repository, and the build identities that pipelines run as.

Secure Source Manager reads a `.cloudbuild/triggers.yaml` file from each repository's default branch and starts Cloud Build itself, so no `google_cloudbuild_trigger` resource takes part. Everything this configuration does is create resources and grant IAM.

**This is a work in progress and nothing is implemented yet.** The sections below record the design, the prerequisites, and the points still to be resolved.

## Landing zone configuration

Three pieces of the design sit outside this configuration, because they are properties of the network and of the certificate authority rather than of the project. Where a FAST landing zone is in use they belong in the networking and security stages; where one is not, they have to be created by whoever owns the VPC and the CA pool. All three are still to be written up properly, and this section is the note to pick that up from.

### The CA pool and the certificate requester grant

A private instance signs its HTTPS certificate through a Certificate Authority Service pool, and inside a VPC Service Controls perimeter that pool is mandatory rather than optional. The two statements you will find in the documentation look contradictory and are not: the API marks `caPool` `Optional. Immutable.` and the instance creation guide says a private instance without one gets a Google-managed certificate, while the VPC Service Controls supported products page requires a working certificate authority before you create an instance inside a perimeter. The narrower statement governs. Because the field is also immutable, an instance created without a pool can never be brought into a perimeter afterwards, which turns a wrong call here into a delete and another hour of instance creation.

The pool must allow CSR-based certificate requests, which is the default when no issuance policy is set, and the CA's key must be 2048 bits. The pool's project and location are independent of the instance's, so neither has to match — useful, because Secure Source Manager runs in far fewer regions than Certificate Authority Service.

The grant that makes it work is `roles/privateca.certificateRequester` for the Secure Source Manager service agent of the *instance* project, placed on the CA pool. Project scope is acceptable for this role. What makes it awkward is that the member string embeds the instance project's number, which does not exist until the project does, so the grant has to be placed by whatever creates the project rather than by this configuration. In the project factory that is `service_agents_project_bindings`, which exists for exactly this shape — a project's own service agents granted roles on projects and folders it does not own:

```yaml
service_agents_project_bindings:
  ssm-certificate-requester:
    service: sourcemanager
    project: $project_ids:sec-core-0
    role: roles/privateca.certificateRequester
```

Enabling `securesourcemanager.googleapis.com` through the project factory is enough to create the service agent and attach `roles/securesourcemanager.serviceAgent` to it, because the project module carries `sourcemanager` as a primary service agent. Google's guide creates it by hand with `gcloud beta services identity create` and grants the role separately; you do not need to. The agent must exist before the first instance is created or creation fails.

The grant lands in a project the project factory does not own, so the factory's own identity needs the right to make it. In FAST that is a delegated, conditioned `roles/resourcemanager.projectIamAdmin` on the CA pool's project or on its parent folder, set where that folder is defined:

```yaml
iam_bindings:
  project_factory:
    role: roles/resourcemanager.projectIamAdmin
    members:
      - $iam_principals:service_accounts/iac-0/iac-pf-rw
    condition:
      title: Project factory delegated IAM grant.
      expression: |
        api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([
          'roles/privateca.certificateRequester',
          'roles/privateca.auditor'
        ])
```

Include `roles/privateca.auditor` in the same condition. The build identities need it on the CA pool's project to fetch the certificate chain, and putting both roles in one delegation avoids coming back for a second one later.

**To document here:** whether the build identities take that grant from the project factory alongside the service agent binding, or from this configuration through `iam_project_roles` on `iam-service-account`. The second is tidier, since the identities are created here, but it needs the delegation to name this configuration's service account rather than the factory's.

### The private DNS zone for the instance hostnames

A private Secure Source Manager instance publishes its hostnames under `REGION.p.sourcemanager.dev`, and those names resolve nowhere useful by default. They are not served by either Private Google Access VIP: they appear in neither the `private.googleapis.com` nor the `restricted.googleapis.com` domain list, so no private access configuration reaches a repository. A private zone attached to the VPC is the only way clients resolve them.

With the generated names the zone holds four A records under `REGION.p.sourcemanager.dev.`: `INSTANCE_ID-PROJECT_NUMBER-api`, `INSTANCE_ID-PROJECT_NUMBER-git` and the bare `INSTANCE_ID-PROJECT_NUMBER` all point at the address of the load balancer fronting the HTTP service attachment, and `INSTANCE_ID-PROJECT_NUMBER-ssh` points at the SSH one.

This configuration sets custom hostnames instead, through `custom_host_config` on the instance, which replaces the generated names with four of your own. The API requires all four and the CA pool signs their certificate, which is a second reason the pool is mandatory here rather than merely available. The zone then covers your own domain, with `api`, `git` and the apex on the HTTP load balancer and `ssh` on the SSH one.

Two things make it worth the extra field. The generated names embed the instance id and the project number, and since nothing about an instance can be changed after creation, a rebuild produces a new instance id and therefore new hostnames in every DNS record, clone URL, credential helper and CI configuration that referenced them. Names you own survive a rebuild: the records repoint and nothing downstream changes.

The second reason applies to anyone running more than one region, and it is the larger one. An instance is regional and immutable, so a second region means a second instance, and with generated names it also means a second DNS suffix — `REGION.p.sourcemanager.dev.` is per-region, so each region needs its own private zone and its own entry in the peered domain list below, both of which have to be added to the landing zone every time a region is added. Custom hostnames let every instance live under one parent domain, `ew4.ssm.example.com` and `ew2.ssm.example.com` beneath `ssm.example.com`, so one zone and one peered domain entry for the parent cover all of them and adding a region touches no landing zone configuration at all. The rest of the design is unchanged: each instance still needs its own CA pool grant, its own pair of load balancers and its own service attachments.

Where the zone lives in a landing zone's DNS design it needs no peering of its own and no cross-project binding, and the records are best created once the load balancers exist and their addresses are reserved. That ordering is the reason to keep them out of this configuration: the addresses are outputs of this setup, and the records that consume them are owned elsewhere.

Creating the zone in this configuration's own project instead is possible but costs more than it looks. Attaching a private zone to a VPC in another project is a cross-project bind, so the identity running Terraform needs `dns.networks.bindPrivateDNSZone` on the host project on top of `compute.networks.get`, and neither comes with any role you would otherwise be granting it. There is no predefined role carrying only the bind permission, so this means a custom role on the host project. Prefer the landing zone's DNS design where one exists.

**To document here:** a snippet of the landing zone side, showing the zone in networking stage data and the records against reserved addresses, alongside the outputs this configuration exposes to feed them.

### The peered DNS domain for the Cloud Build private pool

This one is easy to miss, because everything about it looks like it should already work.

A Cloud Build private pool does not run in your VPC. Its workers run in a Google-managed producer VPC connected to yours by a service networking peering, over a private service access range you allocate. Peering carries routes, not DNS. A worker resolves names against the producer network's resolver, so the private zone above is invisible to it — the zone is attached to your network and the worker is not on your network.

The failure this produces is confusing: the route to the load balancer exists and works, but `git clone` fails at name resolution, because the hostname resolved through public DNS instead.

A peered DNS domain fixes it. It tells service networking to forward queries for a given suffix from the producer network back to the consumer network's resolver, so the worker's lookup lands in your private zone and returns the load balancer address. It is a property of the peering rather than of the zone, which is why in `net-vpc` it is expressed as `peered_domains` inside `psa_configs` and not anywhere near the zone:

```hcl
psa_configs = [{
  ranges         = { psa-build = "10.0.200.0/24" }
  export_routes  = true
  peered_domains = ["ssm.example.com."]
}]
# tftest skip
```

The suffix is the parent of the instance hostnames, so with custom hostnames one entry covers every instance beneath it and the list does not grow with regions. Using the generated names instead, the entry is `REGION.p.sourcemanager.dev.` and there is one per region.

`export_routes` carries the VPC's subnet routes to the producer network so the pool can reach the load balancers. Google's guide also asks for `--no-export-subnet-routes-with-public-ip` on the peering, which `net-vpc` does not currently express, so check the peering after the first apply.

**To document here:** the same snippet with the surrounding landing zone context, and a note that the private service access range has to not collide with anything else in the VPC's address plan.

## Open points

- **Cross-region access to the load balancers**, settled. Secure Source Manager runs in eleven regions, only two of which are in Europe, so the instance frequently cannot sit in the same region as everything else, and a Cloud Build private pool in another region reaches the regional internal load balancers only if their forwarding rules have global access. `net-lb-proxy-int` defaults `forwarding_rules_config.global_access` to `true`, so the split works without doing anything. Colocating the pool with the instance still drops a cross-region hop from every clone, and remains the better option where the pool's region is free to move.
- **Who places `roles/privateca.auditor` for the build identities.** Covered under the CA pool above. The grant itself is not in question; what is undecided is whether it comes from the project factory or from here through `iam_project_roles`, and therefore which identity the delegation on the CA pool's project has to name.
- **What the load balancer path needs in a Shared VPC service project.** A Private Service Connect NEG plus a regional internal proxy load balancer in a service project may need more than `roles/compute.networkUser` for the compute service agent, in particular on the proxy-only subnet. To be established by building it.
- **Provider gaps.** Pin `hashicorp/google` at 7.44.0 or later: `google_secure_source_manager_repository` gained `service_account` there, and that field is what makes a repository-level service account something the configuration enforces rather than something an operator remembers. `google_developer_connect_connection` still has no Secure Source Manager block, which rules out the Developer Connect alternative to the network path above.

## Security note

A person who can commit to a repository's default branch chooses both the identity a build runs as and the event that starts it, because both live in the triggers file. Worse, the build steps come from the commit that fired the event, so any `pull_request` trigger is a standing grant of its named identity to everyone who can open a pull request against that repository.

Three boundaries do three different jobs here, and only the first is IAM:

- isolation between repositories comes from the set of act-as edges leaving each repository's service account, which is why every repository gets its own and why `roles/iam.serviceAccountUser` is granted on the service account resource and never on a project
- which identities a repository can name at all comes from who may commit to the default branch, so branch protection and CODEOWNERS carry weight that IAM carries elsewhere
- what a `pull_request` trigger's identity may do comes from that identity's own permissions and nothing else, so it has to be safe in the hands of everyone who can open a pull request

The last one is stricter than it sounds: a plan identity that reads Terraform state hands that state to every pull request author, and state files carry secrets in practice.
