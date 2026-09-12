# Secure Source Manager and Cloud Build CI/CD

This setup brings up a private Secure Source Manager instance and the Cloud Build machinery that runs pipelines from its repositories: two internal proxy load balancers that give the instance an address every connected network can reach, a Cloud Build private worker pool, one repository-level service account per repository, and the build identities that pipelines run as.

Secure Source Manager reads a `.cloudbuild/triggers.yaml` file from each repository's default branch and starts Cloud Build itself, so no `google_cloudbuild_trigger` resource takes part.

The design targets a regulated environment. Build workers must have no external IP address. Build traffic must be attributable to the customer's VPC Service Controls perimeter: an API call made from a build step faces the same perimeter as a call made from anywhere else in the environment, and appears in the same audit logs. Those two requirements are why the pool is private and peered to the VPC, and the first apply has to demonstrate them rather than assume them — see the worker pool section.

**This is a work in progress and nothing is implemented yet.** The sections below record the design, the prerequisites, and the points still to be resolved.

## Landing zone configuration

Three pieces of the design sit outside this configuration, because they are properties of the network and of the certificate authority rather than of the project. Where a FAST landing zone is in use they belong in the networking and security stages; where one is not, they have to be created by whoever owns the VPC and the CA pool.

### The CA pool and the certificate requester grant

A private instance signs its HTTPS certificate through a Certificate Authority Service pool, and inside a VPC Service Controls perimeter that pool is mandatory. The API marks `caPool` `Optional. Immutable.` and the instance creation guide says a private instance without one gets a Google-managed certificate, while the VPC Service Controls supported products page requires a working certificate authority before you create an instance inside a perimeter. The narrower statement governs. Because the field is immutable, an instance created without a pool can never join a perimeter afterwards, which turns a wrong call here into a delete and another hour of instance creation.

The pool must allow CSR-based certificate requests, which is the default when no issuance policy is set, and the CA key must be 2048 bits. The pool's project and location are independent of the instance's, so neither has to match — useful, because Secure Source Manager runs in far fewer regions than Certificate Authority Service.

The grant that makes it work is `roles/privateca.certificateRequester` for the Secure Source Manager service agent of the *instance* project, placed on the CA pool. Project scope is acceptable for this role. The member string embeds the instance project's number, which does not exist until the project does, so whatever creates the project places the grant rather than this configuration. In the project factory that is `service_agents_project_bindings`, which exists for this shape — a project's own service agents granted roles on projects and folders it does not own:

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

Include `roles/privateca.auditor` in the same condition. The build identities need it on the CA pool's project to fetch the certificate chain, and putting both roles in one delegation avoids a second one later.

The auditor grant exists for one call. The instance's certificate is signed by our own CA, so nothing on a worker trusts it; before it can clone, a build runs `gcloud privateca pools get-ca-certs`, writes the chain and points git at it. Auditor is read-only across the CA project's resources, which is wider than that one fetch, and it is granted per build identity on a project this configuration does not own. Two things would be better. A custom role holding only the permission `get-ca-certs` needs would keep the shape and narrow the grant. Publishing the bundle to a bucket, ideally a managed folder holding just this chain, would remove the grant and the delegation behind it entirely, since the chain is a public artifact and reading it needs nothing on the CA. Neither is done here; the second is on the TODO list as stage work.

The build identities take `roles/privateca.auditor` from this configuration, through `iam_project_roles` on `iam-service-account`, and the delegation on the CA pool's project names this configuration's service account rather than the factory's. The factory cannot place it: the identities do not exist until this configuration creates them. One more grant crosses an ownership line: `roles/iam.serviceAccountTokenCreator` on the Terraform service accounts the build identities impersonate. For application pipelines those accounts sit next to the application and the grant is placed here through `iam_sa_roles`. For FAST stages they belong to the bootstrap stage, and the binding goes there: the build identities are added as static context entries and named from the automation project's IAM. Stages are few and do not grow, and each moves onto the pipeline only after it has been applied by hand and shown to work, so this is a one-line change per stage rather than a delegation.

### The private DNS zone for the instance hostnames

A private Secure Source Manager instance publishes its hostnames under `REGION.p.sourcemanager.dev`, and those names resolve nowhere useful by default. They appear in neither Private Google Access VIP domain list, so no private access configuration reaches a repository. A private zone attached to the VPC is the only way clients resolve them.

With the generated names the zone holds four A records under `REGION.p.sourcemanager.dev.`: `INSTANCE_ID-PROJECT_NUMBER-api`, `INSTANCE_ID-PROJECT_NUMBER-git` and the bare `INSTANCE_ID-PROJECT_NUMBER` all point at whatever fronts the HTTP service attachment, and `INSTANCE_ID-PROJECT_NUMBER-ssh` at whatever fronts the SSH one. What fronts them is the subject of the access path section below.

This configuration sets custom hostnames instead, through `custom_host_config` on the instance, which replaces the generated names with four of your own. The API requires all four and the CA pool signs their certificate, which is a second reason the pool is mandatory here. The zone then covers your own domain, with `api`, `git` and the apex on the HTTP address and `ssh` on the SSH one.

Custom hostnames are worth the extra field for two reasons. The generated names embed the instance id and the project number, and since nothing about an instance can change after creation, a rebuild produces new hostnames in every DNS record, clone URL, credential helper and CI configuration that referenced them. Names you own survive a rebuild: the records repoint and nothing downstream changes.

The second reason applies to anyone running more than one region. An instance is regional and immutable, so a second region means a second instance, and with generated names it also means a second DNS suffix — `REGION.p.sourcemanager.dev.` is per-region, so each region needs its own private zone, added to the landing zone every time a region is added. Custom hostnames let every instance live under one parent domain, `ew4.ssm.example.com` and `ew2.ssm.example.com` beneath `ssm.example.com`, so one zone covers all of them and adding a region touches no landing zone configuration. Each instance still needs its own CA pool grant, its own service attachments and its own load balancers.

The records point at the two load balancer addresses, which are ordinary internal addresses that peering, VPN and Interconnect carry. One zone serves every connected network, and in a hub and spoke design it goes where the network-wide zones go: the hub, with the spokes reaching it through their peering zone. The addresses are outputs of this configuration and the records are owned by the landing zone, so the zone is created first and the records filled in after the first apply. In the playground that is `pvt-ssm.yaml` under `2-networking/dns/zones/net-core-0`.

The build workers need one more thing, because they sit on the producer side of a private service access peering and peering carries routes but not DNS. A worker resolves against the producer network's resolver and never sees the VPC's zones, so the route to the instance works while `git clone` fails at name resolution. The fix is a peered DNS domain on the peering — `peered_domains` inside `psa_configs` in `net-vpc` — naming the hostname suffix, `ssm.gcp.qix.it.` here.

Creating the zone in this configuration's own project instead is possible but costs more than it looks. Attaching a private zone to a VPC in another project is a cross-project bind, so the identity running Terraform needs `dns.networks.bindPrivateDNSZone` on the host project on top of `compute.networks.get`, and neither comes with any role you would otherwise grant it. No predefined role carries only the bind permission, so this means a custom role on the host project. Prefer the landing zone's DNS design where one exists.

### The private service access peering for the Cloud Build private pool

A Cloud Build private pool never runs in your VPC; the question is only how its workers reach it. With private service access, which is what Google's guide uses and what this configuration does, the workers run in a Google-managed producer VPC joined to yours by a service networking peering over a range you allocate. With Private Service Connect each worker would instead get an interface in a subnet of your own VPC through a network attachment. The second is the better design — no range, no exported routes, and the workers resolve against your VPC's resolver so nothing has to be forwarded — and it is not available: the API refuses the pool with `Private Service Connect feature is unavailable`, an allowlist that Terraform and gcloud both hide by silently creating a pool with no network at all. The evidence is in [SSM-CB.md](SSM-CB.md); this configuration switches to it when the allowlist opens, and that switch is one block on the pool resource plus the landing zone changes.

The peering needs a range, the exported subnet routes so the workers reach the load balancers, and the peered DNS domain from the previous section:

```yaml
psa_configs:
  - ranges:
      psa-build: 10.8.200.0/24
    export_routes: true
    peered_domains:
      - ssm.gcp.qix.it.
```

Google's guide also asks for `--no-export-subnet-routes-with-public-ip`, which `net-vpc` does not express; check the peering after the first apply. The range is regional to nothing — the peering is on the VPC — so the pool's region need not be the instance's. Two consequences follow:

- `no_external_ip` on the pool maps to the peering's egress option and is what keeps the workers off the internet. There is no backstop: the workers run in a Google-managed tenant project in Google's own organisation, where `compute.vmExternalIpAccess` and every other policy of ours has no reach, and a pool with public egress was created here without complaint. A private-egress worker reaches Google APIs through Private Google Access and nothing else; a build that needs the internet needs a different answer.
- The workers arrive from the peered range for firewall purposes, so ingress rules that admit them name `10.8.200.0/24` rather than a subnet.

Whether the workers' API traffic is attributed to your perimeter is the other regulated requirement, and it is a property to prove rather than assume. An earlier private service access pool showed the Google-side tenant project treated as inside the perimeter of the VPC's project, and the first build should confirm it: have a build step call an API the perimeter denies and check that the violation lands in your perimeter's audit logs with the worker as the source.

The pool needs no service account of its own. An identity is named per build, in the triggers file, and the pool only has to admit it. A build identity does need `roles/logging.logWriter`, and that is less optional than it looks: a build running as a user-managed service account has no default log destination, so it must either write to Cloud Logging and say so with `CLOUD_LOGGING_ONLY`, or name a bucket. With neither, the build fails before it runs a step.

## The access path to the instance

A private instance publishes two Private Service Connect service attachments, one for HTTP and one for SSH, and both are computed rather than configured — the instance has no notion of a consumer and no way to create one. The only consumer-side control it carries is `private_config.psc_allowed_projects`, a list of projects permitted to connect, with the instance's own project allowed implicitly. It is immutable like the rest of the instance and allowing a project costs nothing, so list every VPC host project in the organisation at creation.

This configuration fronts each attachment with a regional internal proxy load balancer, as in Google's guide: `net-lb-proxy-int` builds the whole chain — PSC NEG, backend service, target TCP proxy, forwarding rule — from one module block per attachment, on port 443 for HTTP and 22 for SSH, and defaults `forwarding_rules_config.global_access` to `true`, which lets clients in another region of the same VPC connect. That matters here because Secure Source Manager runs in eleven regions and only two of them are in Europe, so the instance usually cannot sit in the region everything else uses. The load balancers need a proxy-only subnet in the instance's region, `europe-west4/ilb-l7-ew4` in the playground.

The load balancer is there for one reason: its forwarding rule address is an ordinary internal address that VPC peering, VPN and Interconnect all carry. A bare Private Service Connect endpoint on the attachment would be cheaper — an address and a forwarding rule — but its address is reachable only from inside its own VPC, so the build workers on their peered producer network, people on the hub and anything on-premises could not use it, and each network would need its own endpoint and its own DNS answer. One address and one zone is the whole gain.

The proxy carries no certificate, because the instance's certificate covers the instance's hostnames and TLS runs end to end from the client to the instance. Custom hostnames therefore do not require the load balancer; they require the CA pool, whose chain the client has to trust.

## Open points

- **Who places the grants on identities this configuration does not own.** `roles/privateca.auditor` comes from here under a delegation, and `roles/iam.serviceAccountTokenCreator` on a FAST stage's Terraform accounts comes from the bootstrap stage, when a stage moves onto the pipeline. See the CA pool section.
- **What the load balancers need in a Shared VPC service project.** NEGs, backend services, proxies and forwarding rules on subnets the service project does not own need `roles/compute.networkUser` scoped somewhere. Which subnets, and whether the compute service agent needs it too, is established by building it.
- **Provider gaps.** Pin `hashicorp/google` at 7.44.0 or later: `google_secure_source_manager_repository` gained `service_account` there, and that field is what makes a repository-level service account something the configuration enforces rather than something an operator remembers. `google_secure_source_manager_branch_rule` lacks `requiredStatusChecks` and `requireCodeOwnerApproval`, both of which the API has, so the merge gate and the code owner requirement are set in the web interface until the provider carries them. `google_developer_connect_connection` still has no Secure Source Manager block, which rules out the Developer Connect alternative to the network path above.

## Security note

A person who can commit to a repository's default branch chooses both the identity a build runs as and the event that starts it, because both live in the triggers file. The build steps come from the commit that fired the event, so any `pull_request` trigger is a standing grant of its named identity to everyone who can open a pull request against that repository. The full escalation analysis lives in [SSM-CB.md](SSM-CB.md); the three boundaries it leaves are:

- isolation between repositories comes from the set of act-as edges leaving each repository's service account, which is why every repository gets its own and why `roles/iam.serviceAccountUser` is granted on the service account resource and never on a project
- which identities a repository can name at all comes from who may commit to the default branch, so branch protection and CODEOWNERS carry weight that IAM carries elsewhere
- what a `pull_request` trigger's identity may do comes from that identity's own permissions and nothing else, so it has to be safe in the hands of everyone who can open a pull request

The last one is stricter than it sounds: a plan identity that reads Terraform state hands that state to every pull request author, and state files carry secrets in practice.

### Two branch rule settings are made by hand

The second boundary is the one the provider cannot fully express today. `google_secure_source_manager_branch_rule` carries neither `requiredStatusChecks` nor `requireCodeOwnerApproval`, although the REST resource `projects.locations.repositories.branchRules` has both, so Terraform can create the rule and protect the branch but cannot set the merge gate or make CODEOWNERS binding. Set both in the web interface, per repository, after the branch rule is created, and set them again if the rule is recreated:

- **Required status checks** — add the build's status check context, so a failing build blocks the merge. Without it the build runs and reports and nothing stops a merge that ignores it.
- **Require code owner approval** — without it CODEOWNERS is advisory, and since committing to the default branch is what decides which identities a repository may name, an advisory CODEOWNERS leaves the second boundary resting on branch protection alone.

Until the provider catches up these are operational steps, not configuration, so nothing detects their absence. Check them when a repository is added. Closing the gap upstream is recorded as follow-up work in [TODO.md](TODO.md).
