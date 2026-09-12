---
date: 2026-09-08
tags: [gcp, secure-source-manager, cloud-build, cicd, iam, private-service-connect, vpc-sc]
status: design
---

# Secure Source Manager and Cloud Build for Terraform pipelines

A person who can commit to a repository's default branch chooses both the identity a build runs as and the event that starts it, because both live in one file inside the repository. IAM bounds the set of identities they can choose. IAM does nothing about which event they pair an identity with, so someone can name the apply identity on a pull request event and get apply privileges without review. Control over who commits to the default branch bounds who can make that pairing.

It does not bound who can use one. The build steps come from the commit that fired the event, so once a `pull_request` trigger exists on the default branch, everyone who can open a pull request runs arbitrary steps as the identity that trigger names. Branch protection governs which identities are reachable; it does not govern what a pull request does with them.

Those two properties shape the whole design, and they are why this pattern suits a customer engagement and does not suit Fabric FAST.

This document is self-contained and is the design; it started in a work vault and moved here on 2026-09-12 to sit next to the implementation. The earlier connectivity survey and the review of an earlier draft have both been deleted; the review's surviving findings are folded in here.

The implementation is this directory, on branch `ludo/ssm-cb`. The template does not plan yet: `main.tf` is a sketch of the module wiring with the gaps marked, [README.md](README.md) carries the landing zone prerequisites, and [TODO.md](TODO.md) tracks every open question including the test list at the end of this document. The one design-blocking gap is closed — `modules/secure-source-manager-instance` now carries the repository service account, so the isolation requirement is Terraform-enforced rather than operator-remembered.

## Contents

- [Requirements](#requirements)
- [How Secure Source Manager starts a build](#how-secure-source-manager-starts-a-build)
- [The triggers file](#the-triggers-file)
- [The identity chain](#the-identity-chain)
- [Which build identities a committer can choose](#which-build-identities-a-committer-can-choose)
- [Escalation from an unreviewed pull request](#escalation-from-an-unreviewed-pull-request)
- [Why this rules out Fabric FAST](#why-this-rules-out-fabric-fast)
- [VPC Service Controls and the two planes](#vpc-service-controls-and-the-two-planes)
- [Resources to create](#resources-to-create)
- [IAM grants](#iam-grants)
- [How a build runs end to end](#how-a-build-runs-end-to-end)
- [The Developer Connect alternative](#the-developer-connect-alternative)
- [Terraform provider gaps](#terraform-provider-gaps)
- [Caveats](#caveats)
- [What we still need to test](#what-we-still-need-to-test)
- [Sources](#sources)

## Requirements

The customer requirements we are designing against, as stated so far:

- Secure Source Manager runs as a Private Service Connect instance
- the whole design sits inside a VPC Service Controls perimeter
- Cloud Build runs on a private worker pool, which is fixed for data locality and for VPC Service Controls, and holds whatever else changes
- no single identity is reachable from every pipeline in every repository, either by default or through a configuration mistake such as omitting the repository-level service account
- a shared identity that calls Cloud Build is acceptable, provided it never becomes the identity the build runs as when the build names none
- the result has to be enterprise grade, with the caveats written down

Two things are out of scope for now and we will revisit both once a design exists and we have tested it. Fabric FAST integration is out. Terraform provider gaps are a consequence of the design rather than a constraint on it, so we record them and solve them later, by upstream contribution or by a workaround.

## How Secure Source Manager starts a build

Secure Source Manager reads a triggers file from the default branch of each repository and starts Cloud Build itself. No `google_cloudbuild_trigger` resource takes part, and Terraform provisions nothing on the trigger side. Everything Terraform does here is create resources and grant IAM.

The service reads the file and the associated commit at two moments. For a push event it reads when the push completes. For a pull request event it reads when the pull request changes are pulled from.

Build status appears in the web interface next to the commit, as success, warning or failure. A branch protection rule can require a successful status check from a named trigger before a merge.

## The triggers file

The file lives at `.cloudbuild/triggers.yaml` on the default branch. It holds a list under `triggers`, and each entry takes these fields:

- `name` is required, holds alphanumeric characters and dashes, cannot start or end with a dash, and stays under 64 characters
- `project` is optional and names the project where Cloud Build runs, defaulting to the Secure Source Manager project
- `configFilePath` is optional and defaults to `.cloudbuild/cloudbuild.yaml`
- `eventType` is optional, takes `push` or `pull_request`, and defaults to `push`
- `includedGitRefs` and `ignoredGitRefs` take RE2 regular expressions, both default to empty meaning no restriction, and Secure Source Manager checks the ignored list first
- `includedFiles` and `ignoredFiles` take RE2 regular expressions over changed files
- `serviceAccount` is required and takes the form `projects/PROJECT_ID/serviceAccounts/ACCOUNT`
- `disabled` is optional and defaults to false
- `substitutions` takes a string map

Secure Source Manager supplies these substitutions to the build: `TRIGGER_NAME`, `COMMIT_SHA`, `REVISION_ID`, `SHORT_SHA`, `REPO_NAME`, `REPO_FULL_NAME`, `REF_NAME` and `TRIGGER_BUILD_CONFIG_PATH`. Your own substitution names begin with an underscore and use uppercase letters, underscores and numbers.

The legacy Cloud Build service account cannot be used, because of its documented limitations.

## The identity chain

Two identities do the work, and they do different jobs.

The triggering identity calls Cloud Build when an event fires. By default this is the Secure Source Manager service agent, `service-REPOSITORY_PROJECT_NUMBER@gcp-sa-sourcemanager.iam.gserviceaccount.com`, which exists once per project and serves every repository in it. Google recommends replacing it per repository with a user-managed service account, which the API calls a repository level service account or BYOSA. The documentation says that a user-managed service account can hold `iam.serviceAccounts.actAs` on custom Cloud Build service accounts and describes the default service agent as unable to.

The build identity is the service account named in `serviceAccount:`, and it runs the build steps.

The chain from a commit to a running build has two hops:

1. The Secure Source Manager service agent mints a token for the repository's BYOSA, which needs `roles/iam.serviceAccountTokenCreator` on that BYOSA.
2. The BYOSA creates the build naming a build identity, which needs `roles/iam.serviceAccountUser` on that build service account.

## Which build identities a committer can choose

The set of build identities available to a committer in repository X is exactly the set of service accounts on which repository X's BYOSA holds `roles/iam.serviceAccountUser`. Nothing else narrows it. Three rules follow, and all three protect the requirement that no identity reaches every pipeline:

- give every repository its own BYOSA, because two repositories sharing one BYOSA share its whole reachable set
- grant `roles/iam.serviceAccountUser` and `roles/iam.serviceAccountTokenCreator` on the service account resource every time, never on a project, because a project-level grant of `roles/iam.serviceAccountUser` lets that BYOSA run as every service account in the project and recreates the problem in full
- treat the BYOSA as mandatory on every repository, because a repository without one falls back to the shared service agent

## Escalation from an unreviewed pull request

Two distinct escalations live here, and the second is the one that constrains the design.

The first needs default branch access. A committer picks the build identity and the event type from the same file, so IAM cannot separate plan from apply. Give repository X's BYOSA the right to act as both a plan identity and an apply identity, and a committer writes `eventType: pull_request` alongside `serviceAccount: <apply identity>` and reaches apply privileges on an unmerged pull request. Branch protection on the default branch stops this one.

The second needs nothing but the ability to open a pull request. Secure Source Manager reads the triggers file from the default branch, but Cloud Build reads the build configuration file from the commit that fired the event, which for a pull request is the head of the pull request branch. So the trigger fixes the identity and the pull request author fixes the steps. Any `pull_request` trigger on the default branch is therefore a standing grant of its named identity to everyone who can open a pull request against that repository, and branch protection does not narrow it, because nothing here is being merged.

Three boundaries do three jobs, and only the first is IAM:

- isolation between repositories comes from the set of act-as edges leaving each BYOSA, and IAM enforces it
- which identities a repository can name at all comes from who may commit to the default branch, which means branch protection rules and CODEOWNERS on the branch that holds the triggers file
- what a `pull_request` trigger's identity may do comes from that identity's own permissions and nothing else, so it has to be safe in the hands of every person who can open a pull request

The third boundary is stricter than it first sounds. A plan identity that reads Terraform state hands the state file to every pull request author, and state files carry secrets in practice. Treat the read-only Terraform account's blast radius as public to the repository's contributor set, or run plan against nothing that matters.

Workload identity federation behaves differently and it is worth recording why. A GitHub or GitLab token carries the branch, so the principal set binds impersonation to a branch and the pipeline definition cannot forge it. Secure Source Manager puts the equivalent decision in a file that the pipeline's own authors control, so repository governance carries a weight that IAM carried before.

The read-from-head behaviour is inferred rather than verified: it is how Cloud Build pull request triggers work elsewhere, it is the only way a pull request check can be useful, and a review of an earlier draft asserted it from service source. It is on the test list.

## Why this rules out Fabric FAST

FAST grants apply privileges on the strength of a merge to a protected branch, and it expresses that through branch-scoped principal sets that a pipeline author cannot rewrite. This pattern cannot make the same promise, because the pipeline author edits the file that names the privileges. Shipping it as a FAST stage would offer a guarantee FAST does not hold here.

We keep it as a customer pattern with the escalation written down, and we revisit FAST once we have tested the design. What FAST contributes when workload identity federation drops out is small: service accounts for CI/CD that can impersonate the Terraform ones, and a workflow template.

## VPC Service Controls and the two planes

Secure Source Manager is fully supported by VPC Service Controls. The supported products page lists the integration as GA, says you can protect the service with a perimeter, and names it `securesourcemanager.googleapis.com`, so that service goes into the perimeter's restricted list. The same entry states the two prerequisites the rest of this design already carries: a working certificate authority before you create an instance inside a perimeter, and Private Service Connect before you access one.

The reason those two sit together is that the product has two planes with different network properties, and conflating them is the most expensive mistake available here. `securesourcemanager.googleapis.com` is an ordinary Google API serving instances, locations and operations. It is a `*.googleapis.com` name, it is a VPC Service Controls supported service, and it therefore reaches over the restricted VIP at `199.36.153.4/30` like any other. Everything anyone actually uses — repositories, git, issues, pull requests, the web interface — is served by the instance itself on `sourcemanager.dev` hostnames, and those appear in neither VIP's domain list on the Private Google Access page: not among the names private.googleapis.com enumerates, and not under restricted.googleapis.com. No amount of private access configuration reaches a repository. That is why Private Service Connect is a prerequisite rather than one option among several, and why the network section below is as long as it is.

The practical split is that a Terraform runner inside the perimeter can create instances and repositories over the restricted VIP with no VPC connectivity at all, while anything that clones, pushes or reads a file needs the Private Service Connect path.

## Resources to create

### Source

- a Certificate Authority Service CA pool and CA, created before the instance, with CSR-based certificate requests enabled and a key size of 2048 bits, plus `roles/privateca.certificateRequester` for the Secure Source Manager service agent, granted on the CA pool's project rather than on the pool. Project scope is acceptable for this role, and the project factory can express it: `service_agents_project_bindings` grants a project's own service agents roles on projects and folders it does not own, which is the only way to place a grant whose member string embeds the granting project's number. The guide takes the pool's project and location as separate parameters from the instance's, so neither has to match, and a root or a subordinate CA both work. Two documents disagree about whether the pool is optional, and the disagreement is only apparent, because they are scoped differently. The instance creation guide says you need your own certificate authority for custom domains and that a private instance without one gets a Google-managed certificate; `caPool` carries `Optional. Immutable.` in the REST reference, `--ca-pool` is not required by `gcloud source-manager instances create`, and the Terraform resource does not mark it required either. The VPC Service Controls supported products page is narrower and governs us: it says you need a working certificate authority configured before creating an instance inside a perimeter. So the pool is optional for a private instance in general and mandatory for ours. The immutability is what makes getting this wrong expensive rather than annoying, since an instance created without a pool can never be brought into a perimeter afterwards
- a Secure Source Manager instance with a private configuration, which takes up to 60 minutes to create and publishes two service attachments, one for HTTP and one for SSH. Check the region first, because the product runs in eleven and the list is thin: `us-central1`, `us-east1`, `northamerica-northeast1`, `asia-east1`, `asia-northeast1`, `asia-northeast3`, `australia-southeast1`, `europe-west2`, `europe-west4`, `me-west1` and `me-central2`. Europe has two, and a landing zone whose primary region is anything else will be placing this instance away from everything around it
- one repository per pipeline, each carrying its own BYOSA
- a branch protection rule on each default branch, which the escalation described above makes necessary

### Network

The instance publishes two service attachments and has no notion of an endpoint. The only consumer-side control on it is `psc_allowed_projects`, a list of projects permitted to connect, with the instance's own project implicit. Everything past that is ordinary Private Service Connect: any number of endpoints, in any number of networks, in any allowed project. The list is immutable like the rest of the instance, so it has to name every project that may ever hold an endpoint, and since allowing a project only permits endpoints there, the safe list is every VPC host project in the organisation.

What decides the shape of this section is a single limit. **A Private Service Connect endpoint is reachable only from inside its own VPC network** — its address is not carried by VPC peering, VPN or Interconnect, and an endpoint must sit in the service attachment's region. So the list is short when every client shares a VPC with the endpoints, and long when they do not.

With every client on one VPC:

- a way for the VPC to resolve the instance hostnames: a private Cloud DNS zone attached to it, or, where the landing zone centralises zones in a hub that must not see these answers, a response policy bound to the VPC alone
- an endpoint for the HTTP service attachment and a second for the SSH one, both in the instance's region, with global access if any client sits in another region of the same VPC
- four A records, or four local-data rules: `-api`, `-git` and the bare instance name on the HTTP endpoint address, `-ssh` on the SSH one

When a client is on another VPC, each additional network needs its own endpoint, its project added to `psc_allowed_projects`, and its own records for the same four names, because the name now resolves to a different address in each. A client that is not on a Google Cloud VPC at all — anything on-premises over VPN or Interconnect — cannot be served this way, and that case forces the alternative below.

The alternative is what Google's guide documents, and its whole purpose is to replace an endpoint address with one that peering does carry:

- a Private Service Connect network endpoint group for each service attachment
- a proxy-only subnet with purpose `REGIONAL_MANAGED_PROXY` and role `ACTIVE`, using a mask of `/26` or shorter, with `/23` recommended
- a regional backend service with scheme `INTERNAL_MANAGED` for each network endpoint group
- a regional target TCP proxy for each backend service
- a forwarding rule on port 443 for HTTP and a second on port 22 for SSH, both `INTERNAL_MANAGED` and premium tier, with global access for cross-region clients

The A records then point at the forwarding rule addresses and one zone serves every connected network. Note what the proxy is not doing: it is a target TCP proxy and carries no certificate, because the instance's own certificate covers its hostnames and TLS runs end to end from the client. Custom hostnames therefore never require a load balancer — they require the CA pool whose chain the client trusts.

### Build

A Cloud Build private pool never runs in your VPC, and there are two mechanisms for reaching it. They are mutually exclusive blocks on the same resource.

**Private service access**, which Google's guide uses, puts the workers in a Google-managed producer VPC joined to yours by a peering:

- a global address with purpose `VPC_PEERING`, at prefix length 24
- a peering to `servicenetworking.googleapis.com` over that range
- a peered DNS domain with suffix `REGION.p.sourcemanager.dev.`, so the pool resolves the private names, and the private zone shared with service producers explicitly
- the peering updated to export custom routes, with `--no-export-subnet-routes-with-public-ip`
- a pool created with `--peered-network` and `--no-public-egress`

The peered DNS domain is the part that catches people. Peering carries routes and not DNS, so a worker resolves against the producer network's resolver and cannot see a zone attached to yours. The failure looks nothing like a DNS failure: the route works, and `git clone` fails because the hostname resolved through public DNS.

**Private Service Connect**, through a network attachment, gives each worker an interface in a subnet of your own VPC instead:

- a subnet to draw worker addresses from, one address per concurrent worker, in the pool's region
- a network attachment on it, with `ACCEPT_AUTOMATIC` — the manual alternative wants the producer's project number, which for Cloud Build is Google's
- a pool created with `--network-attachment`, `--disable-public-ip-address`, and `--route-all-traffic` if public egress should also leave through your VPC and its Cloud NAT

Nothing has to be forwarded, because a worker holding an interface in the VPC resolves against the VPC's resolver and sees its private zones directly. There is no range to allocate and no peering whose exported routes need checking, and the workers become ordinary subnet-scoped clients for firewall purposes. Since they are then on the VPC, they can also reach a Private Service Connect endpoint directly, which is what makes the short form of the network section above possible.

### Identity

- the Secure Source Manager service agent, which has to exist and hold `roles/securesourcemanager.serviceAgent` on its project before the first instance is created, or creation fails. Google's guide creates it by hand with `gcloud beta services identity create` and grants the role separately; the Fabric project module carries `sourcemanager` as a primary service agent with that role attached, so enabling `securesourcemanager.googleapis.com` through the project factory does both
- one BYOSA per repository, set through the repository's `service_account` attribute so no repository can be created without one
- as many build service accounts as the split between plan and apply needs
- the Terraform service accounts the build identities impersonate

## IAM grants

| grant on | principal | role |
| --- | --- | --- |
| the repository's BYOSA | Secure Source Manager service agent | roles/iam.serviceAccountTokenCreator |
| each permitted build service account | the repository's BYOSA | roles/iam.serviceAccountUser |
| the project where builds run | the repository's BYOSA | roles/cloudbuild.builds.editor |
| the project where builds run | the repository's BYOSA | roles/serviceusage.serviceUsageConsumer |
| the project where builds run | the repository's BYOSA | roles/cloudbuild.workerPoolUser |
| the Secure Source Manager instance | the build service account | roles/securesourcemanager.instanceAccessor |
| the repository | the build service account | roles/securesourcemanager.repoReader |
| the CA pool's project | the Secure Source Manager service agent | roles/privateca.certificateRequester |
| the CA pool project | the build service account | roles/privateca.auditor |
| the build project | the build service account | roles/logging.logWriter |
| each Terraform service account | the build service account | roles/iam.serviceAccountTokenCreator |

Grant `roles/securesourcemanager.repoReader` on the repository. Google's own guide grants it on the instance project, which lets one build read every repository there and breaks the isolation requirement.

People need their own roles. Configuring a repository service account requires `roles/iam.serviceAccountUser` on that service account, and Secure Source Manager checks it when you create or update the repository. Connecting a repository to Cloud Build requires `roles/securesourcemanager.repoWriter` on the repository and `roles/securesourcemanager.instanceAccessor` on the instance. Perimeter work requires `roles/accesscontextmanager.policyAdmin` on the organisation.

Where the BYOSA lives in a different project from the builds, disable the `iam.disableCrossProjectServiceAccountUsage` organisation policy in the project that holds the service account. The troubleshooting guide names this as a cause of builds failing to start.

## How a build runs end to end

1. Someone pushes a commit or opens a pull request.
2. Secure Source Manager reads `.cloudbuild/triggers.yaml` from the default branch and matches the event against the reference and file filters.
3. The Secure Source Manager service agent mints a token for the repository's BYOSA.
4. The BYOSA creates a build in the project the entry names, running as the service account the entry names, and Cloud Build checks the act-as permission.
5. The build starts on the private worker pool, whose workers hold an interface in the VPC through the network attachment.
6. The build resolves the git hostname against the VPC's resolver, which answers from the private zone, and reaches the instance through the A record, the Private Service Connect endpoint and the service attachment. On the private service access variant the resolution instead crosses a peered DNS domain, and the path runs through a forwarding rule, a target TCP proxy, a backend service and a network endpoint group before the service attachment.
7. The build fetches the certificate chain with `gcloud privateca pools get-ca-certs`, writes it to `cacert.pem`, and sets a git credential helper for the git hostname so that clone uses its own token.
8. The build impersonates the read-only or read-write Terraform service account and runs plan or apply.

Which Terraform account it reaches depends on which build identity the trigger entry named, which brings us back to branch protection.

## The Developer Connect alternative

Google recommends Developer Connect over the network path above for private integrations between Secure Source Manager and Cloud Build, and calls the Private Service Connect route the more complex alternative for people unwilling to expose a git proxy endpoint. Developer Connect replaces the load balancers, the DNS records and the certificate handling with a connection and a repository link, and the trigger entry gains a `devConnectGitRepositoryLink` field naming the link.

Three things stop us designing on it today:

- the connection type has no Terraform surface, as recorded below
- the proxy endpoint sits on the public internet, protected by IAM, and Google's advice is to fence it with VPC Service Controls
- reaching it from a pool with no public egress costs us the perimeter's main mitigation, as below

The proxy lives at `REGION-git.developerconnect.dev`. A worker pool created with `--no-public-egress` routes outbound traffic into the peered network, where that name resolves to a public address it cannot reach, so the pool needs a private zone pointing the domain at a Google access VIP. Only one VIP serves it: the [domain options table](https://cloud.google.com/vpc/docs/configure-private-google-access) lists `*.developerconnect.dev` under private.googleapis.com at `199.36.153.8/30`, and it is absent from restricted.googleapis.com at `199.36.153.4/30`, which carries only services that support VPC Service Controls. Putting private.googleapis.com into the build network gives that network a path to every Google API whether the perimeter covers it or not, which is the exfiltration mitigation the perimeter exists for. That is the real cost of this path, and it is larger than the load balancer set it replaces.

The proxy also carries read operations only and blocks `git push` using the Developer Connect service agent identity. A connection must sit in the same region as its instance and cannot be repointed at another instance afterwards. The Developer Connect service agent needs `roles/securesourcemanager.developerConnectLinker` on the instance project, and the Secure Source Manager service agent needs `roles/developerconnect.viewer`, or another role carrying `developerconnect.gitRepositoryLinks.get`, on the Developer Connect project.

One documentation discrepancy to resolve if we take this path: the Developer Connect page names the file `.cloudbuild/trigger.yaml`, and the Secure Source Manager pages name it `.cloudbuild/triggers.yaml`.

## Terraform provider gaps

Pin `hashicorp/google` and `hashicorp/google-beta` at 7.44.0 or later. One gap remains at that version.

`google_secure_source_manager_repository` gained `service_account` and `scan_config` in 7.44.0, released 2026-08-11, under [pull request 28662](https://github.com/hashicorp/terraform-provider-google/pull/28662). Earlier versions, including 7.43.0, carry neither. The mechanism our isolation requirement depends on is therefore Terraform-managed, which matters: BYOSA becomes something the pipeline enforces rather than something an operator remembers.

`google_developer_connect_connection` still has no Secure Source Manager block on provider main. It exposes `bitbucket_cloud_config`, `bitbucket_data_center_config`, `crypto_key_config`, `github_config`, `github_enterprise_config`, `gitlab_config`, `gitlab_enterprise_config` and `http_config`, and nothing for an instance, so the connection the Developer Connect path needs cannot be created in Terraform. The API has the field and gcloud exposes it as `--secure-source-manager-instance-config`, so the contribution is small. `google_developer_connect_git_repository_link` takes a generic `parent_connection` and `clone_uri`, so it would work as soon as the connection exists.

Everything else the design needs exists: `google_secure_source_manager_instance` with a `private_config` block, `google_secure_source_manager_branch_rule`, instance and repository IAM resources, `google_cloudbuild_worker_pool`, and the whole Private Service Connect and load balancing set.

One provider detail worth carrying into planning: default timeouts on `google_secure_source_manager_instance` operations were raised to 120 minutes from 60 in [pull request 22483](https://github.com/hashicorp/terraform-provider-google/pull/22483), with the note that operations could take longer than an hour.

## Caveats

- a committer to the default branch can pair any reachable build identity with any event type, which is the first escalation described above
- every person who can open a pull request can run arbitrary steps as the identity any `pull_request` trigger names, because the build configuration comes from their own commit, which is the second escalation described above and the one branch protection does not reach
- a plan identity that can read Terraform state exposes that state to the same set of people, and state files carry secrets in practice
- Google's Private Service Connect guide grants `roles/securesourcemanager.repoReader` at project level, so following it as written lets every build read every repository in the project and breaks the isolation requirement outright, and you grant the role on the repository instead
- the repository-level service account is optional in the API, and a repository created without one falls back to the shared service agent, so nothing in the platform enforces our isolation requirement for us, though Terraform can from 7.44.0 onwards
- the documentation says `serviceAccount` is required in the triggers file and never says what happens when you leave it out, so the behaviour our requirement turns on is undocumented, and a trigger dropped at parse time reports no status check at all rather than a failing one
- nothing about an instance can be changed after creation. `projects.locations.instances` exposes create, delete, get, list and the IAM methods and no `patch`, `gcloud source-manager instances` has no `update` subcommand, and the provider marks the whole resource immutable, so `is_private`, `ca_pool`, `custom_host_config`, `psc_allowed_projects`, the CMEK key and workforce identity federation are each a one-shot decision. Getting one wrong costs a delete, another hour of creation, and a new instance ID inside every hostname, DNS record and clone URL that depends on it
- the branch rule resource carries pull request, review count, comment, stale review and linear history settings and no required status check, so the merge gate this design leans on may be a web interface setting rather than a Terraform one; check the REST reference before depending on it
- a zone or response policy attached to a network that holds no endpoint resolves the hostnames to an address that network cannot reach, and the failure is a connect timeout rather than a name error; attach it only where an endpoint exists, and remove response policy rules when switching to the load balancer path, since a policy overrides any zone added later
- endpoints and the load balancer path are alternatives rather than layers, and Google's guide opens by telling you to release any endpoints you already configured before building the load balancers. Switching from one to the other later is therefore not purely additive
- the documentation creates the first repository from a bastion host inside the VPC, using the instance's own data plane API hostname, but the Terraform resource builds its URLs from the public control plane at `securesourcemanager.googleapis.com`, so the binding constraint on the runner is perimeter membership rather than VPC connectivity
- a build running as your own service account cannot use the default logs bucket, so send logs to Cloud Logging or to a bucket you create
- clients verifying TLS need the certificate chain in every trust store they use, including the one inside each container image a pipeline runs
- VPC Service Controls changes take up to 30 minutes to propagate, and requests fail with `Error 403: Request is prohibited by organization's policy` during that window
- opening the web interface from inside a perimeter needs browser access to three URLs beyond the instance itself: `https://accounts.google.com`, `https://LOCATION-sourcemanagerredirector-pa.client6.google.com` for the instance's own region, and `https://lh3.googleusercontent.com`
- a `SERVICE_NOT_ALLOWED_FROM_VPC` audit log violation caused by GKE limitations can be ignored, which the supported products page states explicitly and which is worth knowing before someone spends a day on it

## What we still need to test

The infrastructure we bring up exists to answer these, and the first two can each invalidate the design above:

1. Confirm that a pull request build runs the `.cloudbuild/cloudbuild.yaml` from the pull request head commit rather than from the default branch. Push a pull request whose build configuration differs from the default branch's and see which steps execute. The whole third boundary above turns on this, and it is currently inferred.
2. Find out whether omitting `serviceAccount` from a triggers file fails the build, drops the trigger silently, or falls back to an identity, and if it falls back, which one. Then find out what a dropped trigger does to a branch protection rule that requires its status check. Our isolation requirement depends on the first half and our merge gate on the second.
3. Find out whether `google_secure_source_manager_repository` can create a repository in a Private Service Connect instance from a runner outside the VPC but inside the perimeter. The provider targets the public control plane, so the expected answer is yes and the expected failure mode is a perimeter one.
4. Confirm that a worker whose only interface comes from a network attachment can reach a Private Service Connect endpoint on the same VPC. The short form of the network section rests on it, and it is inferred from the interface being an ordinary VPC interface rather than tested.
5. Find out what a worker pool with no external IP and `route_all_traffic` can reach, which with a network attachment is a question about your own Cloud NAT and egress rules rather than about the pool. If we revisit Developer Connect, establish whether the proxy at `REGION-git.developerconnect.dev` is reachable through private.googleapis.com, and price what adding that VIP does to the perimeter.
6. Closed on 2026-09-12 without testing: `psc_allowed_projects` is immutable. The Magic Modules definition marks the instance resource immutable as a whole, and the API has no update method. The list has to be right on the first apply.
7. Confirm that a branch protection rule requiring a status check blocks a merge when the check fails, and first confirm that such a rule can be expressed at all outside the web interface, since the provider's branch rule has no field for it.
8. Measure how long instance creation actually takes. The documentation says up to 60 minutes and the provider's own timeout is now 120.
9. Revalidate that the Secure Source Manager control plane can create builds in the build project under VPC Service Controls. It is the one hop in the sequence above that originates on Google infrastructure rather than inside a perimeter project, carrying a BYOSA token. An earlier test with a private service access pool showed the Google-side tenant project being treated as inside the perimeter of the project owning the connected VPC. That should hold for a network attachment too, but it was observed with PSA and has not been with PSC.

Two questions were closed by cross-checking rather than by testing. Terraform can set the repository service account from 7.44.0. Whether the Secure Source Manager service agent can itself hold `iam.serviceAccounts.actAs` on a custom Cloud Build service account is still unresolved — the documentation implies it cannot and a review asserted it can — but the design mandates a BYOSA on every repository, so the answer changes nothing here.

## Sources

- [Connect Secure Source Manager to Cloud Build](https://cloud.google.com/secure-source-manager/docs/connect-cloud-build)
- [Triggers file schema](https://cloud.google.com/secure-source-manager/docs/triggers-file-schema)
- [Create a triggers file](https://cloud.google.com/secure-source-manager/docs/create-triggers-file)
- [Connect Cloud Build to a Private Service Connect instance](https://cloud.google.com/secure-source-manager/docs/connect-cloud-build-private-service-connect)
- [Private network integrations](https://cloud.google.com/secure-source-manager/docs/private-network-integrations)
- [Troubleshoot Secure Source Manager](https://cloud.google.com/secure-source-manager/docs/troubleshoot)
- [Create a Private Service Connect Secure Source Manager instance](https://cloud.google.com/secure-source-manager/docs/create-private-service-connect-instance)
- [Secure Source Manager instances REST reference](https://cloud.google.com/secure-source-manager/docs/reference/rest/v1/projects.locations.instances)
- [Secure Source Manager repositories REST reference](https://cloud.google.com/secure-source-manager/docs/reference/rest/v1/projects.locations.repositories)
- [Branch protection overview](https://cloud.google.com/secure-source-manager/docs/branch-protection-overview)
- [Configure Secure Source Manager in a VPC Service Controls perimeter](https://cloud.google.com/secure-source-manager/docs/configure-service-perimeter)
- [VPC Service Controls supported products](https://cloud.google.com/vpc-service-controls/docs/supported-products), for the Secure Source Manager entry
- [Secure Source Manager locations](https://cloud.google.com/secure-source-manager/docs/locations)
- [Connect Developer Connect to Secure Source Manager](https://cloud.google.com/developer-connect/docs/connect-secure-source-manager)
- [Developer Connect overview](https://cloud.google.com/developer-connect/docs/overview)
- [Configure and use Developer Connect proxy](https://cloud.google.com/developer-connect/docs/configure-git-proxy)
- [Cloud Build triggers](https://cloud.google.com/build/docs/triggers)
- [Configure user-specified service accounts in Cloud Build](https://cloud.google.com/build/docs/securing-builds/configure-user-specified-service-accounts)
- [Configure Private Google Access](https://cloud.google.com/vpc/docs/configure-private-google-access), for the domain options table
- [Terraform Google provider changelog](https://github.com/hashicorp/terraform-provider-google/blob/main/CHANGELOG.md)
- [Magic Modules Secure Source Manager repository definition](https://github.com/GoogleCloudPlatform/magic-modules/blob/main/mmv1/products/securesourcemanager/Repository.yaml)
- [Magic Modules Secure Source Manager instance definition](https://github.com/GoogleCloudPlatform/magic-modules/blob/main/mmv1/products/securesourcemanager/Instance.yaml)
