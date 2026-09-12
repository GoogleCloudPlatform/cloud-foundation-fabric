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

The build identities take `roles/privateca.auditor` from this configuration, through `iam_project_roles` on `iam-service-account`, and the delegation on the CA pool's project names this configuration's service account rather than the factory's. The factory cannot place it: the identities do not exist until this configuration creates them. One more grant crosses an ownership line: `roles/iam.serviceAccountTokenCreator` on the Terraform service accounts the build identities impersonate. For application pipelines those accounts are created next to the application and the grant is placed here through `iam_sa_roles`. For FAST stages they belong to the bootstrap stage, and the binding goes there: the build identities are added as static context entries and named from the automation project's IAM. Stages are few and do not grow, and each is moved onto the pipeline only after it has been applied by hand and shown to work, so this is a one-line change per stage rather than a delegation.

### The private DNS zone for the instance hostnames

A private Secure Source Manager instance publishes its hostnames under `REGION.p.sourcemanager.dev`, and those names resolve nowhere useful by default. They are not served by either Private Google Access VIP: they appear in neither the `private.googleapis.com` nor the `restricted.googleapis.com` domain list, so no private access configuration reaches a repository. A private zone attached to the VPC is the only way clients resolve them.

With the generated names the zone holds four A records under `REGION.p.sourcemanager.dev.`: `INSTANCE_ID-PROJECT_NUMBER-api`, `INSTANCE_ID-PROJECT_NUMBER-git` and the bare `INSTANCE_ID-PROJECT_NUMBER` all point at whatever fronts the HTTP service attachment, and `INSTANCE_ID-PROJECT_NUMBER-ssh` at whatever fronts the SSH one. What that is — a Private Service Connect endpoint or a load balancer — is the subject of the access path section below, and the zone is the same either way.

This configuration sets custom hostnames instead, through `custom_host_config` on the instance, which replaces the generated names with four of your own. The API requires all four and the CA pool signs their certificate, which is a second reason the pool is mandatory here rather than merely available. The zone then covers your own domain, with `api`, `git` and the apex on the HTTP address and `ssh` on the SSH one.

Two things make it worth the extra field. The generated names embed the instance id and the project number, and since nothing about an instance can be changed after creation, a rebuild produces a new instance id and therefore new hostnames in every DNS record, clone URL, credential helper and CI configuration that referenced them. Names you own survive a rebuild: the records repoint and nothing downstream changes.

The second reason applies to anyone running more than one region, and it is the larger one. An instance is regional and immutable, so a second region means a second instance, and with generated names it also means a second DNS suffix — `REGION.p.sourcemanager.dev.` is per-region, so each region needs its own private zone, added to the landing zone every time a region is added. Custom hostnames let every instance live under one parent domain, `ew4.ssm.example.com` and `ew2.ssm.example.com` beneath `ssm.example.com`, so one zone covers all of them and adding a region touches no landing zone configuration at all. The rest of the design is unchanged: each instance still needs its own CA pool grant, its own service attachments and its own endpoints.

Where the zone lives in a landing zone's DNS design it needs no peering of its own and no cross-project binding, and the records are best created once the endpoints exist and their addresses are known. That ordering is the reason to keep them out of this configuration: the addresses are outputs of this setup, and the records that consume them are owned elsewhere.

With endpoints, use a response policy rather than a zone. In a hub and spoke design the hub holds the network-wide zones and the spokes reach them through a peering zone, but an endpoint address is the opposite of network-wide: it is valid only inside the VPC that holds it, and a second network gets a different address for the same name. What the endpoint phase needs is therefore a per-network override of four names, which is what a Cloud DNS response policy is. Four local-data rules in a policy bound to the endpoint's VPC and to nothing else, and no zone for a domain the landing zone does not otherwise serve, no ordering against the peering zone, and no environment zone carrying records the hub can see but not reach. A second network that gets its own endpoint gets its own rules in its own policy. A VPC binds to one response policy, so the rules share whatever policy that network already has.

A response policy wins over every zone, including one added later. That is the property that makes it right here and the one to remember when the load balancer fallback below is taken: the forwarding rule address is network-wide, the records then belong in a hub zone, and the spoke rules have to be removed or the spoke keeps answering with the dead endpoint address. The rules name the domain, so the cleanup is visible. Attaching a zone to a network that holds no endpoint, or leaving the rules in place after the switch, produces the same failure either way: a connect timeout rather than a name error.

Creating the zone in this configuration's own project instead is possible but costs more than it looks. Attaching a private zone to a VPC in another project is a cross-project bind, so the identity running Terraform needs `dns.networks.bindPrivateDNSZone` on the host project on top of `compute.networks.get`, and neither comes with any role you would otherwise be granting it. There is no predefined role carrying only the bind permission, so this means a custom role on the host project. Prefer the landing zone's DNS design where one exists.

**To document here:** a snippet of the landing zone side, showing the zone in networking stage data and the records against reserved addresses, alongside the outputs this configuration exposes to feed them.

### The network attachment for the Cloud Build private pool

A Cloud Build private pool never runs in your VPC; the question is only how its workers reach it. There are two mechanisms and they produce quite different designs.

With **private service access**, which is what Google's guide uses, the workers run in a Google-managed producer VPC joined to yours by a service networking peering over a range you allocate. With **Private Service Connect**, which is what this configuration uses, each worker instead gets an interface in a subnet of your own VPC through a network attachment you create. In Terraform the two are mutually exclusive blocks on the same resource, `network_config.peered_network` against `private_service_connect.network_attachment`.

Choosing the attachment removes an entire class of problem, and the problem is worth stating because it is easy to miss and its failure mode is confusing. Peering carries routes, not DNS. A worker on the producer side of a private service access peering resolves names against the producer network's resolver, so the private zone above is invisible to it, and the result is that the route to the instance exists and works while `git clone` fails at name resolution, having resolved the hostname through public DNS. Fixing that needs a peered DNS domain — a property of the peering rather than of the zone, which is why in `net-vpc` it appears as `peered_domains` inside `psa_configs`, nowhere near the zone it makes visible.

A worker on a network attachment has an interface in your VPC, so it resolves against your VPC's resolver and sees the zone directly. There is nothing to forward, no range to allocate, and no peering whose exported routes have to be checked. What it needs instead is a subnet to draw worker addresses from, one address per concurrent worker, and an attachment on it:

```yaml
network_attachments:
  cloudbuild-ew8:
    subnet: europe-west8/na
    automatic_connection: true
```

`automatic_connection` accepts any producer that names the attachment. The manual alternative wants the producer's project number in `producer_accept_lists`, and for Cloud Build that number is Google's and not something you can look up.

The attachment is regional and must be in the pool's region, which need not be the instance's. Two further consequences follow:

- `route_all_traffic` on the pool decides whether the workers' public egress leaves through your VPC as well as their private traffic. With it on, builds reach the internet through your Cloud NAT and under your egress controls, which is usually the point of running a private pool at all. With it off, only RFC 1918 and RFC 6598 destinations take the attachment.
- The workers become clients of your VPC for firewall purposes, so ingress rules that admit them are ordinary subnet-scoped rules rather than rules against a peered range.

**To document here:** the landing zone snippet with its surrounding context, and a note on sizing the attachment subnet against expected build concurrency.

## The access path to the instance

A private instance publishes two Private Service Connect service attachments, one for HTTP and one for SSH, and both are computed rather than configured — the instance has no notion of an endpoint and no way to create one. The only consumer-side control it carries is `private_config.psc_allowed_projects`, a list of projects permitted to connect, with the instance's own project allowed implicitly. Everything else is ordinary Private Service Connect: any number of endpoints, in any number of networks, in any allowed project, may attach to the same service attachment.

This configuration creates one endpoint per attachment and no load balancers, both endpoints in a single `net-address` block. `global_access` on them is what lets a client in another region of the same VPC connect, which matters here: Secure Source Manager runs in eleven regions and only two of them are in Europe, so the instance usually cannot sit in the region everything else uses.

The constraint that shapes the rest is that **a Private Service Connect endpoint is reachable only from inside its own VPC**. Its address is not propagated over VPC peering, and not over VPN or Interconnect either. Two consequences follow:

- Each additional client *network* needs its own endpoint, in the attachment's region, and its project added to `psc_allowed_projects` — which is granted per project, so it admits every network in that project, present and future. Because the same hostname then resolves to a different address in each network, each also needs its own response policy rules for the four names. A second endpoint is cheap; a second set of rules carrying the same four names with different answers is a thing that drifts.
- No endpoint can serve a client that is not on a Google Cloud VPC at all. On-premises access over HA VPN or Interconnect cannot be solved this way.

The fallback for both cases is the design in Google's guide: a regional internal proxy load balancer per attachment, with a Private Service Connect NEG as its backend. Its forwarding rule is an ordinary internal address, which peering, VPN and Interconnect all carry, so one address serves every connected network and the DNS zone stays single. `net-lb-proxy-int` builds the whole chain — NEG, backend service, target TCP proxy, forwarding rule — from one module block per attachment, and defaults `forwarding_rules_config.global_access` to `true`.

Note what the proxy is *not* doing. It is a target TCP proxy and carries no certificate, because the instance's certificate covers the instance's hostnames and TLS runs end to end from the client to the instance. Custom hostnames therefore do not require a load balancer; they require the CA pool, whose chain the client has to trust. The proxy exists solely to give the service attachment an address that networks other than its own can route to.

## Open points

- **Whether the endpoint-only path holds.** The clients that matter today are the Cloud Build workers, which sit on the dev spoke through their network attachment and so share a VPC with the endpoint. Human clients on the hub, and anything on-premises, do not, and moving either onto this instance means adding an endpoint plus response policy rules, or switching to the load balancer fallback above. The switch is cheap and local — two module blocks and a changed DNS record — which is the reason to start without it.
- **`psc_allowed_projects` is immutable, so list every project that may ever need an endpoint.** The provider marks the whole instance resource immutable and the API has no update method, so the list is fixed at creation and admitting a project later is a rebuild. Allowing a project costs nothing, because it only permits endpoints to be created there. Put every VPC host project in the organisation on the list, and in particular the hub's, since that is where people are and an endpoint on the spoke does not reach them.
- **Who places the grants on identities this configuration does not own.** Covered under the CA pool above: `roles/privateca.auditor` comes from here under a delegation, and `roles/iam.serviceAccountTokenCreator` on a FAST stage's Terraform accounts comes from the bootstrap stage, when a stage is moved onto the pipeline.
- **What the endpoint needs in a Shared VPC service project.** An endpoint is a forwarding rule and an address on a subnet the service project does not own, so it needs `roles/compute.networkUser` scoped somewhere. Which subnets, and whether the compute service agent needs it too, is to be established by building it.
- **Provider gaps.** Pin `hashicorp/google` at 7.44.0 or later: `google_secure_source_manager_repository` gained `service_account` there, and that field is what makes a repository-level service account something the configuration enforces rather than something an operator remembers. `google_developer_connect_connection` still has no Secure Source Manager block, which rules out the Developer Connect alternative to the network path above.

## Security note

A person who can commit to a repository's default branch chooses both the identity a build runs as and the event that starts it, because both live in the triggers file. Worse, the build steps come from the commit that fired the event, so any `pull_request` trigger is a standing grant of its named identity to everyone who can open a pull request against that repository.

Three boundaries do three different jobs here, and only the first is IAM:

- isolation between repositories comes from the set of act-as edges leaving each repository's service account, which is why every repository gets its own and why `roles/iam.serviceAccountUser` is granted on the service account resource and never on a project
- which identities a repository can name at all comes from who may commit to the default branch, so branch protection and CODEOWNERS carry weight that IAM carries elsewhere
- what a `pull_request` trigger's identity may do comes from that identity's own permissions and nothing else, so it has to be safe in the hands of everyone who can open a pull request

The last one is stricter than it sounds: a plan identity that reads Terraform state hands that state to every pull request author, and state files carry secrets in practice.
