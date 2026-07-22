# GCP Landing Zone Design — Phased, HIPAA-Ready-Not-HIPAA-Now

**Status:** Draft v2 for review (amended 2026-07-22: staging environment front-loaded, see §3/§11)
**Date:** 2026-07-14
**Context:** Greenfield GCP org for an early-stage, cost-conscious startup. Product is a fleet of mini PCs deployed in consumer households; all PHI/health data stays **on-device**. Cloud handles APIs + WebSocket connections, OTA/fleet coordination, and normal SaaS account data (names, emails, addresses, billing — PII, not PHI). Direct-to-consumer today; possible healthcare (Business Associate) relationships and cloud PHI storage later. M365/Entra ID for identity. Single US region, multi-region possible later.

---

## 1. Compliance Posture — Read This First

**HIPAA does not apply to you today.** HIPAA binds covered entities (providers, plans, clearinghouses) and their business associates. A direct-to-consumer device company with no covered entity in the chain is neither. What *does* apply now:

- **FTC Health Breach Notification Rule** — covers consumer health devices/apps outside HIPAA. Post-GoodRx/BetterHelp, the FTC enforces this actively: unauthorized disclosure of identifiable health data (including to ad/analytics SDKs) is a "breach." This is your biggest *actual* regulatory exposure today.
- **State consumer-health privacy laws** — especially **Washington My Health My Data Act** (broad, private right of action, applies to health data of WA consumers regardless of where you're based) and CCPA/CPRA's sensitive-data category. These require consent for collection/sharing of consumer health data and honor deletion rights.
- **State breach-notification laws** for the account PII you hold.
- (Flag, out of scope here: if the device makes health claims/diagnoses, check FDA software-as-medical-device rules.)

**Strategic consequence:** you don't need a HIPAA-grade cloud now. You need a **well-built, secure-by-default landing zone** whose *hard-to-retrofit* elements are done correctly on day one, so that becoming a BA later is a bounded project (weeks of config + paperwork), not a re-platforming. That's exactly what this design does.

The devices themselves are where the sensitive data lives, so the strongest security story today is **on-device**: full-disk encryption (LUKS bound to TPM), verified/secure boot, signed updates, minimal local attack surface. That's product engineering, not landing zone, but it's what a regulator or journalist will actually ask about.

---

## 2. Phasing Strategy: Front-Load vs Defer

The test for front-loading: *is it expensive, disruptive, or impossible to retrofit?* Config you can flip on later is deferred; anything structural, historical, or habit-forming is done now.

### Front-load (Phase A — now)

| Item | Why it can't wait | Cost |
|---|---|---|
| Cloud Identity org + Entra ID federation, **group-based IAM only** | Retrofitting user-based IAM grants to groups across a live org is pure toil; identity is the root of everything | Free |
| FAST bootstrap + Terraform-only changes via GitHub Actions (WIF, **no SA keys ever**) | Habits and key sprawl are near-impossible to unwind; keyless from commit #1 | Free |
| Resource hierarchy, naming prefix, project factory conventions | Project IDs are immutable; folder moves ripple through IAM/logging/policy | Free |
| **Org policies** (no public IPs, no SA keys, domain-restricted IAM, public-bucket ban, US-only locations…) | Free guardrails; retrofitting onto live workloads causes outages, doing it first causes nothing | Free |
| **Org-wide audit log sinks incl. Data Access logs** | Logs cannot be backfilled. If you later need to show history (breach forensics, FTC inquiry, future audit), it exists or it doesn't | ~$0 at your volume; storage pennies |
| CIDR plan with room for envs/regions | Renumbering live VPCs is one of the worst days in infra | Free (it's a spreadsheet) |
| Shared VPC + PSC (not legacy peering) for managed services | Migrating Cloud SQL/Memorystore from peering to PSC later means downtime | Free |
| `data-classification` labels/tags on every project from the factory | Classification applied retroactively is guesswork | Free |
| **VPC-SC perimeter in dry-run mode** | The config is easy; the pain is enforcing on a live system. Dry-run from early on means you see every would-be violation for months before you ever enforce — turning the scariest retrofit into a checkbox | Free |
| CMEK (via KMS Autokey) on the **primary user/account database only** | The one store most likely to grow sensitive data; Cloud SQL cannot add CMEK to an existing instance — it's a migrate-or-born-with-it feature | ~$1–3/mo |

### Defer (Phase B — triggered by cloud PHI / BA status)

| Item | Why it's safe to defer | Trigger to activate |
|---|---|---|
| **Google BAA** | Self-serve click-through, free, minutes of work | First BA contract or first PHI-in-cloud design |
| VPC-SC **enforcement** | Dry-run has been soaking; enforcement is a flag flip + exception review | PHI in cloud |
| CMEK everywhere | New PHI stores get CMEK at creation; nothing to retrofit because they don't exist yet | Each new PHI datastore |
| SCC Premium/Enterprise, Access Transparency, Enhanced support | Subscriptions — activate when the risk profile justifies the spend | PHI in cloud, or first enterprise security review |
| IAM PAM (just-in-time prod access), DLP discovery scans | Config-only additions | PHI in cloud |
| Assured Workloads HIPAA folder | Wrapper applied to a folder; evaluate then | BA status |
| HIPAA administrative package (SRA, policies, training, officers) | Paperwork + process; ~4–6 weeks of part-time effort | Before first PHI in prod |
| 6-year log retention bucket-lock | Start with 13-month retention; retention can be *raised* going forward (never lowered on locked buckets — so don't lock long yet) | BA status |
| Multi-region / DR | Regional-only now; log/backup buckets multi-region from day one (cheap, and backups are the thing you want surviving a regional event) | Customer/contract demand |

**The punchline:** almost everything worth front-loading is free. The phased approach costs you almost nothing in Phase A and saves you SCC Premium (~$ thousands/yr), Enhanced support, and a premature compliance program. (Staging was originally on this deferred list too — front-loaded 2026-07-22 per partner agreement; see §3, §11.)

---

## 3. Resource Hierarchy

```
Organization: stayhome-ai.com
│
├── fldr: Bootstrap            # FAST stage-0: automation projects, TF state, WIF pools
├── fldr: Common
│   ├── prj: log-audit-0       # org log sinks (locked-ish bucket + BQ dataset)
│   └── prj: sec-core-0        # KMS (Autokey), org-shared security tooling
├── fldr: Networking
│   ├── prj: net-dev-0         # Shared VPC host — dev
│   ├── prj: net-staging-0     # Shared VPC host — staging
│   └── prj: net-prod-0        # Shared VPC host — prod
├── fldr: Development
│   └── prj: dev-*             # service projects via project factory
├── fldr: Staging
│   └── prj: staging-*         # service projects via project factory
├── fldr: Production           # ← VPC-SC perimeter (dry-run), tightest policies
│   └── prj: prod-*
└── fldr: Sandbox              # experimentation; relaxed policies, hard budget cap
```

- **Three environments (dev, staging, prod)** — decided 2026-07-22 with partners; staging was originally
  deferred to Phase B but front-loaded now. Environments are a data-driven map in tfvars, so this was a
  map entry, not a refactor — exactly as originally planned. Plain names — no `-1` suffixes (uniqueness
  lives in project IDs, which FAST already prefixes/suffixes).
- **FAST proper** (stages 0-bootstrap, 1-resman, 2-security, 2-networking, 2-project-factory), simplest networking variant, pinned release. Full rationale vs. a slimmed custom layout: the compliance-critical plumbing FAST generates — audit log sinks, WIF CI/CD, per-stage least-privilege SAs — is precisely what hand-rolled setups get wrong, and it's what makes Phase B a config change instead of a rebuild.

---

## 4. Identity & Access

- **Cloud Identity Free** on `stayhome-ai.com` (domain-verify via DNS TXT), **federated with Entra ID**: SAML SSO + SCIM provisioning of users *and groups*. Joiners/leavers managed once, in Entra; MFA/Conditional Access enforced there (passkeys/FIDO2 for anyone with GCP access).
- **Groups, not users, in every IAM binding** (`grp-gcp-org-admins@`, `grp-gcp-devops@`, `grp-gcp-developers@`, `grp-gcp-auditors@`, …). Group definitions live in Entra; Terraform references them.
- **Break-glass:** 2 non-federated super-admin accounts, hardware security keys, credentials offline, log-based alert on any use. Super admins are deliberately excluded from SSO.
- **No service account keys** (org policy enforced). CI/CD via WIF; workloads via attached SAs / GKE Workload Identity.
- Devs get broad rights in dev, read-only in prod; prod writes go through Terraform/CI. (PAM for time-boxed human elevation is a Phase B add.)

---

## 5. Networking

- Per-environment **Shared VPC**, one host project each. No hub-and-spoke, no appliances — add only when a concrete requirement appears.
- **Region:** `us-central1`. CIDR plan from 10.0.0.0/8: `10.0/12` prod-r1, `10.16/12` prod-r2 (future), `10.64/12` staging-r1, `10.128/12` dev-r1, rest reserved. Never reuse ranges across envs.
- **No external IPs** (org policy). Cloud NAT for egress. Ingress **only** via global external HTTPS LB + **Cloud Armor**. GCLB terminates WebSockets natively — your device connections ride the same front door (set 30-min+ backend timeouts for long-lived sockets).
- **Private Google Access** everywhere; hierarchical firewall policies (default-deny) at folder level; human SSH only via **IAP** (no bastions).
- **GKE Autopilot, private cluster**, Workload Identity, one cluster per env. Binary Authorization + Artifact Registry with vulnerability scanning from the first deployment — cheap now, culture-forming.
- Managed data services (Cloud SQL, Memorystore) attach via **Private Service Connect**.

---

## 6. Device Fleet ↔ Cloud (the actual product surface)

The landing zone must serve a fleet of household devices. Cloud-side implications:

- **Device identity:** per-device credentials issued at provisioning — either certificates from **CA Service** (DevOps tier, ~$20/mo/CA + $0.30/cert) for mTLS, or per-device tokens/keys bound to a device record. mTLS at the LB is the stronger pattern; start with what your device stack supports, but make device identity **first-class and revocable** from day one (a stolen mini PC must be excommunicable in minutes).
- **Connectivity:** HTTPS APIs + WebSockets through GCLB/Cloud Armor. Consider **Pub/Sub** as the command/telemetry backbone behind the socket layer.
- **The undecided remote-access question — my recommendation: "OTA + telemetry only" as the default posture.**
  - Devices *pull* signed OTA updates (device-side updater: Mender/RAUC/SWUpdate class) and *push* non-sensitive telemetry. No standing interactive access from cloud to device.
  - If support genuinely needs interactive access, make it **user-initiated, time-boxed, per-session, and audited** — never a fleet-wide standing capability.
  - Why it matters beyond security: if cloud systems/staff can reach into devices holding health data, then under a future BA arrangement your **entire cloud management plane drags into HIPAA scope**. A pull-only update model keeps the compliance boundary at the device edge — this is the cheapest compliance decision you will ever make, and it's an architecture decision, so it's effectively front-loaded whether you like it or not.
- **Telemetry discipline:** treat device telemetry as radioactive-by-default. No health-adjacent signals, no raw audio/video, no content-derived data in telemetry. Define an explicit telemetry schema and review additions in PRs — this is your main FTC HBNR exposure.
- **No third-party ad/analytics SDKs** touching anything health-adjacent (device or companion app). This is exactly what GoodRx/BetterHelp were fined for.

---

## 7. Security Baseline (Phase A)

- **Org policies** (day one, org-wide): domain-restricted IAM; no SA keys/uploads; no VM external IPs; Shielded VMs; no default-network creation; uniform bucket-level access + public-access prevention; Cloud SQL public-IP ban; `gcp.resourceLocations` = US; restricted LB types. Sandbox folder gets documented, targeted relaxations — never Production.
- **Logging:** org-level sinks for Admin Activity **and Data Access logs (all services)** → multi-region GCS bucket (13-month retention, *not* bucket-locked yet) + BQ dataset for queries. Log-based alerts: break-glass use, org-policy/IAM changes at org+folder level, KMS key destruction scheduling, (later) VPC-SC denials.
- **SCC Standard** (free) with findings triaged weekly. Premium/Enterprise deferred.
- **Encryption:** Google default at rest everywhere, except **CMEK via Autokey on the primary account/user database** (born with it, since it can't be added to an existing Cloud SQL instance). TLS externally everywhere; app-layer TLS for anything sensitive.
- **VPC-SC:** perimeter defined around Production in **dry-run** from Phase A. Ingress allowances modeled for GitHub Actions WIF principals and workforce access levels. Enforcement is Phase B.
- **Secrets:** Secret Manager only. **Backups:** automated Cloud SQL backups + PITR, GCS versioning; restore test twice a year.
- Budgets + alerts on every project (project factory injects them); hard cap on Sandbox.

---

## 8. What Cannot Be Automated with Terraform (Manual Bootstrap Runbook)

1. **Cloud Identity signup + domain verification** (DNS TXT on stayhome-ai.com) — this *creates* the GCP Organization; Terraform can't.
2. **Super admin / break-glass accounts** + hardware keys + offline recovery codes.
3. **Billing account** creation and payment method.
4. **ToS acceptance**; later, **BAA acceptance** (Phase B, console click-through).
5. **Entra ID federation** — Google-side SAML SSO profile (Admin console) and Entra-side enterprise app + SCIM; the trust exchange is manual (Entra side is partially terraformable via `azuread` afterward).
6. **FAST stage-0 first apply** — one human with Org Admin runs bootstrap locally once; it creates state buckets, WIF pools, stage SAs. All subsequent applies run from GitHub Actions.
7. **Support plan** purchase; **SCC Premium** subscription (Phase B).
8. **Some quota increases**; GitHub org creation/app authorization (repo settings themselves are terraformable).

---

## 9. CI/CD — Terraform via GitHub Actions

- **Workload Identity Federation**: WIF pool trusts GitHub OIDC, attribute conditions pin `repository` + `ref` + `environment`; per-stage service accounts impersonable only by the matching repo/branch. Zero long-lived credentials. FAST bootstrap generates this wiring.
- **Monorepo** with per-stage directories and path-filtered workflows (lower overhead than FAST's default repo-per-stage for a small team).
- **Flow:** PR → `terraform plan` as PR comment → review → merge → `apply` through a GitHub Environment with required reviewers for prod-affecting stages.
- **CI guardrails:** fmt/validate, tflint, `gcloud terraform vet` (org-policy/custom constraints) or OPA, Checkov/trivy config scan.
- GitHub-hosted runners are fine for foundation Terraform (Google APIs via VPC-SC ingress allowances when enforcement comes). Self-hosted runners only if workflows ever need private-network access — not day one.

---

## 10. Phase B Playbook — "We're Storing PHI in the Cloud Now"

Pre-scripted so it's a project, not a scramble:

1. Sign **Google BAA** (and BAAs with every vendor touching PHI — including any LLM APIs; Vertex AI is BAA-covered, third-party model APIs need their own). PHI must never reach GitHub, error trackers, or analytics without a BAA.
2. Verify every service in the PHI path is on Google's **HIPAA-included services** list (make it a project-factory checklist item).
3. Flip **VPC-SC to enforced** on prod after reviewing months of dry-run logs; extend the same perimeter behavior to staging.
4. New PHI datastores **born with CMEK** (Autokey); DLP discovery scans over prod storage; raise log retention toward 6 years and bucket-lock.
5. Activate **SCC Premium**, **Access Transparency**, Enhanced support, **PAM** for JIT prod access.
6. **HIPAA administrative package**: Security Risk Assessment, written policies (incident response w/ 60-day breach clock, sanctions, contingency/DR, workstation), designate Security & Privacy Officers, workforce training, quarterly access reviews (Entra access reviews + group IAM make this cheap). Consider Vanta/Drata — doubly justified if SOC 2 is on the roadmap.
7. **App-layer duties** (not landing zone): audit trails of who viewed which record, session management, de-identification pipelines for analytics.
8. Evaluate **Assured Workloads** HIPAA package for the Production folder.

**PHI-ready definition of done:** BAA signed · VPC-SC enforced · Data Access logs with long locked retention · CMEK on PHI stores · no SA keys / no external IPs (org-policy-verified) · break-glass tested · SRA + IR plan documented · workforce trained.

---

## 11. Rough Phase A Run-Rate

Order-of-magnitude, before app workloads, now three environments (dev/staging/prod, updated 2026-07-22): GKE Autopilot control planes (~$74/mo × 3 envs, minus free-tier credit for one ≈ $148/mo), Cloud NAT (~$35/mo × 3 ≈ $105/mo), global LB + Cloud Armor (~$25–50/mo), Cloud SQL — prod HA instance (~$60–120/mo) + staging/dev non-HA instances (~$20–40/mo combined, HA restricted to production per the born-with-it constraint in §7), logging/storage/KMS (single-digit $), CA Service if used (~$25/mo). **Foundation ≈ $350–550/mo**; the deferred Phase B items (SCC Premium, Enhanced support) are where the four-figure monthly costs hide, and they're all off until triggered.

---

## 12. Outstanding Questions

1. **Remote device access model** — biggest open architecture + future-compliance decision; recommendation in §6 (OTA + telemetry only; session-based, user-consented support access if needed).
2. **Device identity mechanism** — mTLS via CA Service vs token-based? Depends on device provisioning flow; needs a decision before first fleet firmware.
3. **Will the companion app / device make health claims?** → FDA SaMD screening (get a regulatory opinion early if yes).
4. **WA My Health My Data / CCPA readiness** — consent flows and deletion handling are *product* features; who owns them?
5. **SOC 2 timeline** — enterprise/partner deals will demand it before HIPAA does. If <18 months out, buy a compliance platform now.
6. **Payment processing** — Stripe et al. keeps PCI mostly out of scope; confirm nothing card-related lands in your cloud.
7. **LLM/AI processing** — if device or cloud sends any user content to model APIs, which provider, and under what data terms? (Given "stayhome-ai," decide this deliberately, not by default SDK.)
8. **DNS** — where is stayhome-ai.com hosted? Public zones in Cloud DNS?
9. **Support plan** — Standard is fine for Phase A; revisit at Phase B.
10. **Multi-region trigger** — what event forces region 2? For now: multi-region log/backup buckets only, regional everything else.

---

## 13. Build Sequence

| Phase | Work | Mode |
|---|---|---|
| 0 | Cloud Identity + domain verify, break-glass admins, billing, ToS, Entra SSO+SCIM, GitHub org prep | Manual runbook (§8) |
| 1 | FAST 0-bootstrap locally once → all further changes via GitHub Actions | Terraform |
| 2 | 1-resman: folders, org policies, log sinks, groups IAM | Terraform |
| 3 | 2-security: KMS/Autokey, VPC-SC perimeter **dry-run** | Terraform |
| 4 | 2-networking: Shared VPCs, NAT, DNS, firewall, GCLB+Armor front door | Terraform |
| 5 | Project factory; dev + staging + prod GKE Autopilot; app CI/CD w/ Binary Authorization; device identity + WebSocket ingress | Terraform |
| 6 | Ongoing: SCC Standard triage, budget review, telemetry-schema PR discipline | Process |
| B | Phase B playbook (§10) | Triggered |
