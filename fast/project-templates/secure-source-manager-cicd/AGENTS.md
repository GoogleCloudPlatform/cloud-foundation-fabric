# Working in this directory

A FAST project template bringing up a private Secure Source Manager instance and the Cloud Build machinery that runs pipelines from its repositories. It plans and applies. Live as of 2026-09-12: the worker pool in `build-pool.tf`, a test build identity in `main.tf`, and the instance in `ssm-instance.tf`. Not live: the load balancers, the repositories and the identity chain. Work happens on branch `ludo/ssm-cb` in this repository and, for the landing zone side, in `~/dev/tf-playground/fast-config/ludo`.

Read the repository's [AGENTS.md](../../../AGENTS.md) for Fabric conventions and [skills/fabric-builder](../../../skills/fabric-builder/SKILL.md) for how to consume modules. Neither is loaded automatically by the skill tool, because `skills/` in the repository root is not a location the harness discovers.

## The documents, in the order they answer questions

[TODO.md](TODO.md) is the state of the work: every open question, every settled one with the reason and the commit. Read it first; it tells you where the session stopped. Nothing else here is a working list.

[SSM-CB.md](SSM-CB.md) is the design, moved here from the work vault on 2026-09-12, and it is authoritative on behaviour rather than on code. Go to it for how Secure Source Manager starts a build, what the triggers file contains, the identity chain, the two escalation paths, the full IAM grant table, and the caveats. Its last section lists what has never been tested against real infrastructure, and two of those can still invalidate the design.

[README.md](README.md) is this template's own design: what it creates, and the three landing zone prerequisites that sit outside it. It carries the reasoning that would otherwise be re-derived — why the CA pool is mandatory, why a private zone is the only way anything resolves, and why a peered DNS domain is needed on top of it.

[SKETCH.md](SKETCH.md) is the sketch, not code: module blocks with verified attribute names and a trailing section naming what is deliberately owned elsewhere. Its instance and worker pool blocks have been superseded by the live files; its load balancer and identity blocks are still the plan.

## The landing zone side

These live in `~/dev/tf-playground/fast-config/ludo/data` and are not in this repository. Two of them carry long comment blocks recording what was settled and why.

- `2-project-factory/projects/shared/dev-build-ssm-0.yaml` — the instance project. Its header is the best single summary of the design decisions and their reasons.
- `2-project-factory/projects/shared/dev-build-pool-0.yaml` — the build project, holding the worker pool and the build identities.
- `2-networking/vpcs/dev/.config.yaml` — the VPC and the private service access peering for the pool, with `ssm.gcp.qix.it.` as peered domain; `2-networking/dns/zones/net-core-0/pvt-ssm.yaml` is the hub zone for the hostnames.
- `2-security/certificate-authorities/dev-ca-0.yaml` — the CA pool signing the instance certificate.

The two symlinks in this directory, `dev-build-ssm-0.auto.tfvars.json` and `dev-build-ssm-0-rw-providers.tf`, are the project factory's output for this template's automation seat. They are local wiring and deliberately untracked.

## Tooling

`tools/tfdoc.py` and the other Python tools need their dependencies, which the system interpreter does not carry — `marko` in particular. Run them through `uv`, which is what this host has: `uvx --with marko python3 tools/tfdoc.py`, or `uv run` against the repository's requirements files. Module example tests are `uv run pytest -q -k 'secure_source_manager' tests/examples` from the repository root, about 95 seconds. Earlier versions of this file pointed at `~/venv/bin/python3`, which exists on some hosts and not on zb; prefer uv and do not assume a virtualenv. Everything the repository AGENTS.md says about running `terraform fmt`, `check_documentation.py`, yamllint and `check_boilerplate.py` before committing applies here.

## Picking up

Read TODO.md, then the header comment in `dev-build-ssm-0.yaml`. Between them you have the open questions and the settled ones. Skim README.md for anything the task touches, and go to SSM-CB.md only for behaviour you are about to depend on.

Then check `git log --oneline` on `ludo/ssm-cb` and whether the branch has been pushed, because it usually has not.

Two habits are worth carrying in. The provider is authoritative on what fields exist and checking it is cheap, so check it rather than guessing; almost everything this design needs is already in the provider and the gaps have been module surface. The landing zone, the conventions and most of the modules were written by the person you are working with, so ask him rather than inferring intent from his code.

## Handing over

Before the session ends, put each thing where it belongs rather than in a summary message that vanishes.

Tick the TODO item and say what settled it, with the commit. Design reasoning goes in README.md, landing zone reasoning in the relevant `fast-config` YAML header, behaviour and caveats in SSM-CB.md. If a thread was dropped, record the one-line why.

Commit here on `ludo/ssm-cb` and do not push. SSM-CB.md lives here now, so there is no vault side to update.
