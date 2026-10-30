#!/usr/bin/env python3
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "jsonschema>=4.0",
#   "pyyaml>=6.0",
# ]
# ///
"""Validator for FAST Stage 2 (`2-networking`) YAML datasets and Terraform plan.

Performs three verification passes:
1. JSON Schema validation against `fast/stages/2-networking/schemas/*.schema.json`.
2. Semantic, CIDR, `$token` reference, and routing/security guardrail checks.
3. Isolated `terraform init -backend=false`, `terraform validate`, and
   `terraform plan -refresh=false` against a temporary copy of `2-networking`
   with synthetic FAST variables.
"""

from __future__ import annotations

import argparse
import dataclasses
import ipaddress
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Any

import jsonschema
import yaml

STAGE_REL = pathlib.Path("fast/stages/2-networking")
MODELINE_RE = re.compile(r"^\s*#\s*yaml-language-server:\s*\$schema=(\S+)",
                         re.MULTILINE)
TOKEN_RE = re.compile(r"\$([a-z][a-z0-9_]*):([a-zA-Z0-9_./-]+)")

PATH_SCHEMAS: tuple[tuple[re.Pattern[str], str], ...] = (
    (re.compile(r"^defaults\.yaml$"), "defaults.schema.json"),
    (re.compile(r"^folders/.+/\.config\.yaml$"), "folder.schema.json"),
    (re.compile(r"^projects/.+\.yaml$"), "project.schema.json"),
    (re.compile(r"^folders/.+/(?!\.config\.yaml$)[^/]+\.yaml$"),
     "project.schema.json"),
    (re.compile(r"^ncc-hubs/[^/]+\.yaml$"), "ncc-hub.schema.json"),
    (re.compile(r"^nvas/.+\.yaml$"), "nva.schema.json"),
    (re.compile(r"^firewall-policies/.+\.yaml$"),
     "firewall-policy.schema.json"),
    (re.compile(r"^dns/zones/.+\.yaml$"), "dns.schema.json"),
    (re.compile(r"^dns/response-policies/.+\.yaml$"),
     "dns-response-policy-rules.schema.json"),
    (re.compile(r"^vpcs/.+/\.config\.yaml$"), "vpc.schema.json"),
    (re.compile(r"^vpcs/.+/addresses\.yaml$"), "addresses.schema.json"),
    (re.compile(r"^vpcs/.+/firewall-rules/.+\.yaml$"),
     "firewall-rules.schema.json"),
    (re.compile(r"^vpcs/.+/subnets/.+\.yaml$"), "subnet.schema.json"),
    (re.compile(r"^vpcs/.+/vpns/.+\.yaml$"), "vpn.schema.json"),
    (re.compile(r"^vpcs/.+/vlan-attachments/.+\.yaml$"),
     "vlan-attachments.schema.json"),
    (re.compile(r"^vpcs/.+/attachment-groups/.+\.yaml$"),
     "attachment-groups.schema.json"),
)

EXTERNAL_CONTEXT_NAMESPACES = frozenset({
    "custom_roles",
    "email_addresses",
    "folder_ids",
    "iam_principals",
    "kms_keys",
    "security_profile_groups",
    "service_accounts",
    "storage_buckets",
    "tag_keys",
    "tag_values",
    "tag_vars",
    "vpc_sc_perimeters",
})

NON_TOKEN_KEYS = frozenset({"description", "shared_secret", "content"})

DUMMY_FAST_VARS: dict[str, Any] = {
    "billing_account": {
        "id": "000000-111111-222222"
    },
    "organization": {
        "domain": "fast.example.com",
        "id": 123456789012,
        "customer_id": "C00000000",
    },
    "prefix": "fast",
    "service_accounts": {
        "iac-0/iac-pf-rw": "iac-pf-rw@test.iam.gserviceaccount.com",
        "iac-0/iac-pf-ro": "iac-pf-ro@test.iam.gserviceaccount.com",
    },
    "storage_buckets": {
        "iac-0/iac-outputs": "test-iac-outputs"
    },
}


@dataclasses.dataclass
class Issue:
  """Single validation finding."""
  level: str  # "error" | "warn"
  location: str
  message: str

  def to_dict(self) -> dict[str, str]:
    return dataclasses.asdict(self)


def discover_stage_dir(explicit: str | None = None) -> pathlib.Path:
  """Locate `fast/stages/2-networking` relative to this script or environment."""
  if explicit:
    return pathlib.Path(explicit).expanduser().resolve()
  env_dir = os.environ.get("FAST_2_NETWORKING_DIR")
  if env_dir:
    return pathlib.Path(env_dir).expanduser().resolve()
  script_dir = pathlib.Path(__file__).resolve().parent
  for parent in (script_dir, *script_dir.parents):
    candidate = parent / STAGE_REL
    if (candidate / "schemas").is_dir():
      return candidate
  raise FileNotFoundError(
      "Could not locate fast/stages/2-networking; pass --stage-dir.")


def schema_for_relpath(rel: str) -> str | None:
  """Map a dataset-relative POSIX path to its expected JSON schema filename."""
  for rx, schema_name in PATH_SCHEMAS:
    if rx.match(rel):
      return schema_name
  return None


def extract_tokens(obj: Any, parent_key: str = "") -> list[tuple[str, str]]:
  """Recursively extract all `$(namespace):(key)` tokens from parsed YAML."""
  if parent_key in NON_TOKEN_KEYS:
    return []
  found: list[tuple[str, str]] = []
  if isinstance(obj, str):
    for ns, key in TOKEN_RE.findall(obj):
      found.append((ns, key))
  elif isinstance(obj, list):
    for item in obj:
      found.extend(extract_tokens(item, parent_key))
  elif isinstance(obj, dict):
    for k, v in obj.items():
      k_str = str(k) if isinstance(k, str) else ""
      found.extend(extract_tokens(k))
      found.extend(extract_tokens(v, k_str))
  return found


def parse_cidr(
    value: Any,
    location: str,
    field: str,
    issues: list[Issue],
    cidr_ranges: dict[str, str] | None = None,
    strict: bool = True,
) -> ipaddress.IPv4Network | ipaddress.IPv6Network | None:
  """Parse a CIDR string (or `$cidr_ranges:<key>` token) or append an error."""
  if not isinstance(value, str):
    return None
  raw = value
  if raw.startswith("$cidr_ranges:") and cidr_ranges is not None:
    ck = raw.split(":", 1)[1]
    if ck in cidr_ranges:
      raw = cidr_ranges[ck]
    else:
      return None
  elif raw.startswith("$"):
    return None
  try:
    return ipaddress.ip_network(raw, strict=strict)
  except ValueError as exc:
    issues.append(Issue("error", location, f"invalid CIDR in {field}: {exc}"))
    return None


def _vpc_key_from_subpath(rel: str, suffix_pattern: str) -> str | None:
  """Extract `<vpc-key>` from `vpcs/<vpc-key>/<suffix_pattern>`."""
  m = re.match(rf"^vpcs/(.+)/{suffix_pattern}$", rel)
  return m.group(1) if m else None


def validate_dataset_files(
    dataset_dir: pathlib.Path,
    stage_dir: pathlib.Path,
    allow_external_projects: bool = False,
) -> tuple[list[Issue], dict[str, Any]]:
  """Run JSON Schema + semantic/reference/guardrail checks on `dataset_dir`."""
  issues: list[Issue] = []
  schemas_dir = stage_dir / "schemas"
  schema_cache: dict[str, jsonschema.Draft7Validator] = {}

  def get_validator(schema_name: str) -> jsonschema.Draft7Validator | None:
    if schema_name not in schema_cache:
      spath = schemas_dir / schema_name
      if not spath.is_file():
        return None
      schema_cache[schema_name] = jsonschema.Draft7Validator(
          json.loads(spath.read_text(encoding="utf-8")))
    return schema_cache[schema_name]

  for yml_path in sorted(dataset_dir.rglob("*.yml")):
    rel_yml = yml_path.relative_to(dataset_dir).as_posix()
    issues.append(
        Issue(
            "error", rel_yml,
            "FAST 2-networking factories only load '.yaml' files, not '.yml'"))

  yaml_files = sorted(dataset_dir.rglob("*.yaml"))
  if not yaml_files:
    issues.append(
        Issue("error", str(dataset_dir), "no .yaml files found in dataset"))
    return issues, {}

  # Pre-scan VPC `.config.yaml` files to detect disabled `vlan_attachments` factories
  disabled_vlan_vpcs: set[str] = set()
  for ypath in yaml_files:
    rel = ypath.relative_to(dataset_dir).as_posix()
    vpc_k = _vpc_key_from_subpath(rel, r"\.config\.yaml")
    if vpc_k:
      try:
        vdoc = yaml.safe_load(ypath.read_text(encoding="utf-8")) or {}
      except yaml.YAMLError:
        vdoc = {}
      if isinstance(vdoc, dict):
        fcfg = vdoc.get("factories_config") or {}
        if isinstance(fcfg, dict):
          vlan_dir = fcfg.get("vlan_attachments")
          if isinstance(vlan_dir,
                        str) and not (ypath.parent / vlan_dir).is_dir():
            disabled_vlan_vpcs.add(vpc_k)

  docs: dict[str, Any] = {}
  all_tokens: list[tuple[str, str, str]] = []

  # Pass 1: YAML syntax + JSON Schema validation
  for ypath in yaml_files:
    rel = ypath.relative_to(dataset_dir).as_posix()
    vpc_vlan = _vpc_key_from_subpath(rel, r"vlan-attachments/.+\.yaml")
    if vpc_vlan and vpc_vlan in disabled_vlan_vpcs:
      continue

    expected_schema = schema_for_relpath(rel)
    if expected_schema is None:
      issues.append(
          Issue(
              "error", rel,
              "file path does not match any FAST 2-networking factory directory"
          ))
      continue

    raw_text = ypath.read_text(encoding="utf-8")
    m = MODELINE_RE.search(raw_text)
    if m:
      modeline_schema = pathlib.PurePosixPath(m.group(1)).name
      if modeline_schema != expected_schema:
        issues.append(
            Issue(
                "warn", rel,
                f"schema modeline {modeline_schema} differs from expected {expected_schema}"
            ))

    try:
      doc = yaml.safe_load(raw_text)
    except yaml.YAMLError as exc:
      issues.append(Issue("error", rel, f"YAML parse error: {exc}"))
      continue

    if doc is None:
      doc = {}
    docs[rel] = doc

    validator = get_validator(expected_schema)
    if validator is None:
      issues.append(
          Issue("error", rel,
                f"missing schema {expected_schema} in {schemas_dir}"))
      continue

    for err in sorted(validator.iter_errors(doc),
                      key=lambda e: list(e.absolute_path)):
      where = ".".join(str(p) for p in err.absolute_path) or "(root)"
      issues.append(
          Issue("error", rel,
                f"schema ({expected_schema}) {where}: {err.message}"))

    for ns, key in extract_tokens(doc):
      all_tokens.append((rel, ns, key))

  # Build symbol tables for Pass 2
  defaults_doc = docs.get("defaults.yaml") or {}
  ctx_doc = (defaults_doc.get("context") or {}) if isinstance(
      defaults_doc, dict) else {}

  locations: dict[str, str] = dict(ctx_doc.get("locations") or {})
  cidr_ranges: dict[str, str] = dict(ctx_doc.get("cidr_ranges") or {})
  cidr_ranges_sets: dict[str, list[str]] = dict(
      ctx_doc.get("cidr_ranges_sets") or {})

  known: dict[str, set[str]] = {
      "locations":
          set(locations),
      "cidr_ranges":
          set(cidr_ranges),
      "cidr_ranges_sets":
          set(cidr_ranges_sets),
      "addresses":
          set((ctx_doc.get("addresses") or {}).keys()),
      "custom_roles":
          set((ctx_doc.get("custom_roles") or {}).keys()),
      "email_addresses":
          set((ctx_doc.get("email_addresses") or {}).keys()),
      "folder_ids":
          set(),
      "iam_principals":
          set((ctx_doc.get("iam_principals") or {}).keys()),
      "kms_keys":
          set((ctx_doc.get("kms_keys") or {}).keys()),
      "project_ids":
          set((ctx_doc.get("project_ids") or {}).keys()),
      "security_profile_groups":
          set((ctx_doc.get("security_profile_groups") or {}).keys()),
      "storage_buckets":
          set((ctx_doc.get("storage_buckets") or {}).keys()),
      "tag_keys":
          set((ctx_doc.get("tag_keys") or {}).keys()),
      "tag_values":
          set((ctx_doc.get("tag_values") or {}).keys()),
      "vpc_sc_perimeters":
          set((ctx_doc.get("vpc_sc_perimeters") or {}).keys()),
      "networks":
          set(),
      "subnets":
          set(),
      "ncc_hubs":
          set(),
      "ncc_groups":
          set(),
      "routers":
          set(),
      "vpn_gateways":
          set(),
      "vlan_attachments":
          set(),
      "attachment_groups":
          set(),
      "nva_instances":
          set(),
      "nva_addresses":
          set(),
  }

  for name, cidrs in cidr_ranges_sets.items():
    if isinstance(cidrs, list):
      for idx, c in enumerate(cidrs):
        parse_cidr(c, "defaults.yaml",
                   f"context.cidr_ranges_sets.{name}[{idx}]", issues,
                   cidr_ranges)

  for name, c in cidr_ranges.items():
    parse_cidr(c, "defaults.yaml", f"context.cidr_ranges.{name}", issues,
               cidr_ranges)

  # Folders & Projects
  has_project_files = False
  for rel, doc in docs.items():
    if not isinstance(doc, dict):
      continue
    if rel.startswith("folders/") and rel.endswith("/.config.yaml"):
      folder_key = rel[len("folders/"):-len("/.config.yaml")]
      known["folder_ids"].add(folder_key)
    elif rel.startswith("projects/") and rel.endswith(".yaml"):
      has_project_files = True
      proj_key = pathlib.PurePosixPath(rel).stem
      known["project_ids"].add(proj_key)
    elif re.match(r"^folders/.+/(?!\.config\.yaml$)[^/]+\.yaml$", rel):
      has_project_files = True
      proj_key = pathlib.PurePosixPath(rel).stem
      known["project_ids"].add(proj_key)

  # NCC Hubs & Groups (keyed strictly by `name` per factory-ncc.tf:34)
  for rel, doc in docs.items():
    if not isinstance(doc, dict) or not re.match(r"^ncc-hubs/[^/]+\.yaml$",
                                                 rel):
      continue
    hub_name = doc.get("name")
    if not hub_name:
      continue
    hub_name_s = str(hub_name)
    known["ncc_hubs"].add(hub_name_s)
    groups = doc.get("groups") or {}
    if isinstance(groups, dict):
      for gname, gcfg in groups.items():
        known["ncc_groups"].add(f"{hub_name_s}/{gname}")
        if isinstance(gcfg, dict):
          aa = gcfg.get("auto_accept") or []
          if isinstance(aa, list):
            dups = sorted({p for p in aa if aa.count(p) > 1})
            if dups:
              issues.append(
                  Issue(
                      "warn", rel,
                      f"group '{gname}' auto_accept contains duplicate entries: {dups}"
                  ))

  # VPCs, Subnets, Routers, VPNs, VLANs, Attachment Groups, Addresses
  vpc_configs: dict[str, dict[str, Any]] = {}
  vpc_subnets: dict[str,
                    list[tuple[str, str,
                               ipaddress.IPv4Network | ipaddress.IPv6Network,
                               str]]] = {}
  vpc_subnet_stems: dict[str, dict[str, str]] = {}
  vpc_subnet_keys: dict[str, set[str]] = {}
  vpc_routers: dict[str, dict[str, Any]] = {}

  def resolve_region(reg: Any) -> str:
    if isinstance(reg, str) and reg.startswith("$locations:"):
      loc_key = reg.split(":", 1)[1]
      return locations.get(loc_key, loc_key)
    return str(reg or "")

  for rel, doc in docs.items():
    if not isinstance(doc, dict):
      continue
    vpc_key = _vpc_key_from_subpath(rel, r"\.config\.yaml")
    if vpc_key:
      vpc_configs[vpc_key] = doc
      known["networks"].add(vpc_key)
      routers = doc.get("routers") or {}
      if isinstance(routers, dict):
        vpc_routers[vpc_key] = routers
        region_counts: dict[str, int] = {}
        for rkey, rcfg in routers.items():
          known["routers"].add(f"{vpc_key}/{rkey}")
          if isinstance(rcfg, dict):
            rreg = resolve_region(rcfg.get("region"))
            if rreg:
              region_counts[rreg] = region_counts.get(rreg, 0) + 1
              if region_counts[rreg] > 5:
                issues.append(
                    Issue(
                        "error", rel,
                        f"VPC '{vpc_key}' defines >5 Cloud Routers in region '{rreg}' (GCP hard quota is 5)"
                    ))
      for psa_idx, psa in enumerate(doc.get("psa_configs") or []):
        if isinstance(psa, dict):
          for rname, rcidr in (psa.get("ranges") or {}).items():
            pnet = parse_cidr(rcidr, rel,
                              f"psa_configs[{psa_idx}].ranges.{rname}", issues,
                              cidr_ranges)
            if pnet is not None:
              vpc_subnets.setdefault(vpc_key, []).append(
                  (f"psa:{rname}", "psa", pnet, rel))
      for rname, rcfg in (doc.get("routes") or {}).items():
        if isinstance(rcfg, dict) and "dest_range" in rcfg:
          parse_cidr(rcfg.get("dest_range"), rel, f"routes.{rname}.dest_range",
                     issues, cidr_ranges, strict=True)

    m_sub = re.match(r"^vpcs/(.+)/subnets/(.+)\.yaml$", rel)
    if m_sub:
      vpc_key = m_sub.group(1)
      stem = pathlib.PurePosixPath(rel).stem
      prev_rel = vpc_subnet_stems.setdefault(vpc_key, {}).get(stem)
      if prev_rel and prev_rel != rel:
        issues.append(
            Issue(
                "error", rel,
                f"duplicate subnet filename stem '{stem}.yaml' in VPC '{vpc_key}' (also at {prev_rel}); modules/net-vpc keys subnet files by basename"
            ))
      vpc_subnet_stems[vpc_key][stem] = rel

      sub_name = str(doc.get("name") or stem)
      reg_resolved = resolve_region(doc.get("region"))
      is_proxy_or_psc = bool(doc.get("proxy_only") or doc.get("psc"))
      if reg_resolved:
        vpc_subnet_keys.setdefault(vpc_key,
                                   set()).add(f"{reg_resolved}/{sub_name}")
        if not is_proxy_or_psc:
          known["subnets"].add(f"{vpc_key}/{reg_resolved}/{sub_name}")
      net = parse_cidr(doc.get("ip_cidr_range"), rel, "ip_cidr_range", issues,
                       cidr_ranges)
      if net is not None:
        vpc_subnets.setdefault(vpc_key, []).append(
            (sub_name, "primary", net, rel))
      sec_ranges = doc.get("secondary_ip_ranges") or {}
      if isinstance(sec_ranges, dict):
        for sname, scfg in sec_ranges.items():
          scidr = scfg.get("ip_cidr_range") if isinstance(scfg, dict) else scfg
          snet = parse_cidr(scidr, rel, f"secondary_ip_ranges.{sname}", issues,
                            cidr_ranges)
          if snet is not None:
            vpc_subnets.setdefault(vpc_key, []).append(
                (f"{sub_name}:{sname}", "secondary", snet, rel))

    vpc_addr = _vpc_key_from_subpath(rel, r"addresses\.yaml")
    if vpc_addr:
      for ak in (doc.get("internal") or {}):
        known["addresses"].add(f"{vpc_addr}/{ak}")
      for ak, acfg in ((doc.get("psa") or {}).items() if isinstance(
          doc.get("psa"), dict) else ()):
        if isinstance(acfg,
                      dict) and "address" in acfg and "prefix_length" in acfg:
          pnet = parse_cidr(f"{acfg['address']}/{acfg['prefix_length']}", rel,
                            f"psa.{ak}", issues, cidr_ranges)
          if pnet is not None:
            vpc_subnets.setdefault(vpc_addr, []).append(
                (f"addresses.psa:{ak}", "psa", pnet, rel))

    m_vpn = re.match(r"^vpcs/(.+)/vpns/(.+)\.yaml$", rel)
    if m_vpn:
      vpc_key = m_vpn.group(1)
      vpn_name = doc.get("name")
      if vpn_name:
        known["vpn_gateways"].add(f"{vpc_key}/{vpn_name}")
      for tname, tcfg in (doc.get("tunnels") or {}).items():
        if isinstance(tcfg, dict) and "bgp_session_range" in tcfg:
          parse_cidr(tcfg.get("bgp_session_range"), rel,
                     f"tunnels.{tname}.bgp_session_range", issues, cidr_ranges,
                     strict=False)

    m_vlan = re.match(r"^vpcs/(.+)/vlan-attachments/(.+)\.yaml$", rel)
    if m_vlan:
      vpc_key = m_vlan.group(1)
      att_name = doc.get("name")
      if att_name:
        known["vlan_attachments"].add(f"{vpc_key}/{att_name}")

    m_att_grp = re.match(r"^vpcs/(.+)/attachment-groups/(.+)\.yaml$", rel)
    if m_att_grp:
      vpc_key = m_att_grp.group(1)
      grp_name = doc.get("name")
      if grp_name:
        known["attachment_groups"].add(f"{vpc_key}/{grp_name}")

  # Check `network_attachments` in VPC `.config.yaml`
  for vpc_key, vdoc in vpc_configs.items():
    rel = f"vpcs/{vpc_key}/.config.yaml"
    net_atts = vdoc.get("network_attachments") or {}
    if isinstance(net_atts, dict):
      for na_key, na_cfg in net_atts.items():
        if not isinstance(na_cfg, dict):
          continue
        sub_ref = str(na_cfg.get("subnet") or "")
        if sub_ref and sub_ref not in vpc_subnet_keys.get(vpc_key, set()):
          issues.append(
              Issue(
                  "error", rel,
                  f"network_attachments.{na_key}.subnet '{sub_ref}' must be '<resolved-region>/<subnet-name>' matching a subnet in VPC '{vpc_key}' (available: {sorted(vpc_subnet_keys.get(vpc_key, set()))})"
              ))
        for list_field in ("producer_accept_lists", "producer_reject_lists"):
          for item in na_cfg.get(list_field) or []:
            if isinstance(item, str) and item.startswith("$"):
              issues.append(
                  Issue(
                      "error", rel,
                      f"network_attachments.{na_key}.{list_field} does not interpolate '{item}'; use a literal project ID"
                  ))

  # Intra-VPC subnet & PSA overlap checks
  for vpc_key, entries in vpc_subnets.items():
    for i, (n1, _k1, net1, r1) in enumerate(entries):
      for n2, _k2, net2, r2 in entries[i + 1:]:
        if net1.version == net2.version and net1.overlaps(net2):
          issues.append(
              Issue(
                  "error", r1,
                  f"VPC '{vpc_key}' range '{n1}' ({net1}) overlaps with '{n2}' ({net2}) in {r2}"
              ))

  # Reciprocal VPC peering checks & connected VPC pairs for cross-VPC overlap
  connected_vpc_pairs: set[tuple[str, str, str]] = set()
  hub_spokes: dict[str, list[str]] = {}
  peer_neighbors: dict[str, set[str]] = {}

  for vpc_key, vdoc in vpc_configs.items():
    ncc_cfg = vdoc.get("ncc_config")
    if isinstance(ncc_cfg, dict) and isinstance(ncc_cfg.get("hub"), str):
      hub_spokes.setdefault(ncc_cfg["hub"], []).append(vpc_key)

    peerings = vdoc.get("peering_config") or {}
    if not isinstance(peerings, dict):
      continue
    for pkey, pcfg in peerings.items():
      if not isinstance(pcfg, dict):
        continue
      peer_ref = str(pcfg.get("peer_network") or "")
      if peer_ref.startswith("$networks:"):
        peer_vpc = peer_ref.split(":", 1)[1]
        peer_neighbors.setdefault(vpc_key, set()).add(peer_vpc)
        peer_neighbors.setdefault(peer_vpc, set()).add(vpc_key)
        if vpc_key < peer_vpc:
          connected_vpc_pairs.add((vpc_key, peer_vpc, f"peering:{pkey}"))
        peer_doc = vpc_configs.get(peer_vpc)
        if peer_doc is not None:
          peer_map = peer_doc.get("peering_config") or {}
          has_back = any(
              isinstance(v, dict) and
              v.get("peer_network") == f"$networks:{vpc_key}"
              for v in peer_map.values())
          if not has_back:
            issues.append(
                Issue(
                    "error", f"vpcs/{vpc_key}/.config.yaml",
                    f"peering '{pkey}' targets '$networks:{peer_vpc}', but 'vpcs/{peer_vpc}/.config.yaml' has no reciprocal peering back to '$networks:{vpc_key}'"
                ))

  for common_hub, neighbors in peer_neighbors.items():
    sorted_neighbors = sorted(neighbors)
    for i, v1 in enumerate(sorted_neighbors):
      for v2 in sorted_neighbors[i + 1:]:
        connected_vpc_pairs.add((v1, v2, f"peering-via:{common_hub}"))

  for hub_ref, spokes in hub_spokes.items():
    for i, v1 in enumerate(sorted(spokes)):
      for v2 in sorted(spokes)[i + 1:]:
        connected_vpc_pairs.add((v1, v2, f"ncc:{hub_ref}"))

  # Cross-VPC subnet overlap checks across peered or same-NCC-hub VPCs
  for v1, v2, link_label in sorted(connected_vpc_pairs):
    for n1, _k1, net1, r1 in vpc_subnets.get(v1, ()):
      for n2, _k2, net2, r2 in vpc_subnets.get(v2, ()):
        if net1.version == net2.version and net1.overlaps(net2):
          issues.append(
              Issue(
                  "error", r1,
                  f"cross-VPC CIDR overlap over {link_label}: VPC '{v1}' range '{n1}' ({net1}) overlaps with VPC '{v2}' range '{n2}' ({net2} in {r2})"
              ))

  # NVAs: ILB addresses, instance tokens, RA spokes, routes vs advertise
  nva_docs: dict[str, tuple[str, dict[str, Any]]] = {}
  nva_ilb_vpcs: dict[str, set[str]] = {}
  nva_ra_vpcs: dict[str, set[str]] = {}

  for rel, doc in docs.items():
    if not isinstance(doc, dict) or not re.match(r"^nvas/.+\.yaml$", rel):
      continue
    stem = pathlib.PurePosixPath(rel).stem
    nva_name = str(doc.get("name") or stem)
    nva_docs[nva_name] = (rel, doc)

    ilb_cfg = doc.get("ilb_config") if isinstance(doc.get("ilb_config"),
                                                  dict) else {}
    ig_map = (ilb_cfg.get("instance_groups") or doc.get("instance_groups") or
              {})
    nics = ((doc.get("auto_instance_config") or {}).get("nics") or
            []) if isinstance(doc.get("auto_instance_config"), dict) else []

    nic_vpcs: list[str] = []
    for nic_idx, nic in enumerate(nics):
      if not isinstance(nic, dict):
        continue
      net_ref = str(nic.get("network") or "")
      vpc_k = net_ref.split(
          ":", 1)[1] if net_ref.startswith("$networks:") else net_ref
      if vpc_k:
        nic_vpcs.append(vpc_k)

      # Check `advertise` prefixes are covered by `routes` or `masquerade: true`
      adv_list = nic.get("advertise") or []
      route_list = nic.get("routes") or []
      has_masq = bool(nic.get("masquerade"))
      route_nets = [
          parse_cidr(r, rel, f"nics[{nic_idx}].routes", issues, cidr_ranges)
          for r in route_list
      ]
      route_nets_clean = [rn for rn in route_nets if rn is not None]
      for adv in adv_list:
        adv_net = parse_cidr(adv, rel, f"nics[{nic_idx}].advertise", issues,
                             cidr_ranges)
        if adv_net is not None and not has_masq:
          covered = any(rn.version == adv_net.version and adv_net.subnet_of(rn)
                        for rn in route_nets_clean)
          if not covered:
            issues.append(
                Issue(
                    "error", rel,
                    f"NIC {nic_idx} ({net_ref}) advertises '{adv}' in BGP without a covering kernel route in 'routes' (FRR weight 32768 suppresses eBGP route installation, causing a data-plane blackhole)"
                ))

    # Populate `nva_ilb_vpcs` and `$addresses:<vpc>/<nva>` from `ilb_config.forwarding_rules`
    # (or from NIC VPCs when `ilb_config` is used without explicit `forwarding_rules` and no `ncc_ra_config`)
    fr_raw = ilb_cfg.get("forwarding_rules")
    fr_list = list(fr_raw.values()) if isinstance(
        fr_raw, dict) else (fr_raw if isinstance(fr_raw, list) else [])
    if fr_list:
      for fr_cfg in fr_list:
        if isinstance(fr_cfg, dict):
          fr_net = str(fr_cfg.get("network") or "")
          fr_vpc = fr_net.split(
              ":", 1)[1] if fr_net.startswith("$networks:") else fr_net
          if fr_vpc:
            known["addresses"].add(f"{fr_vpc}/{nva_name}")
            nva_ilb_vpcs.setdefault(nva_name, set()).add(fr_vpc)
    elif not doc.get("ncc_ra_config"):
      for vpc_k in nic_vpcs:
        known["addresses"].add(f"{vpc_k}/{nva_name}")
        nva_ilb_vpcs.setdefault(nva_name, set()).add(vpc_k)

    # Populate `$nva_instances:` and `$nva_addresses:` (default `auto_create_instances` is 0 per factory-nva.tf:75)
    total_auto_instances = 0
    if isinstance(ig_map, dict):
      for zone_key, zcfg in ig_map.items():
        count = 0
        if isinstance(zcfg, dict) and isinstance(
            zcfg.get("auto_create_instances"), int):
          count = zcfg["auto_create_instances"]
        total_auto_instances += count
        for idx in range(count):
          inst_key = f"{nva_name}-{zone_key}-{idx}"
          known["nva_instances"].add(inst_key)
          for vpc_k in nic_vpcs:
            known["nva_addresses"].add(f"{inst_key}/{vpc_k}")

    # Check ILB conntrack settings (`ilb_config.connection_tracking` per nva.schema.json)
    ct = ilb_cfg.get("connection_tracking")
    if isinstance(ct, dict):
      if ct.get("track_per_session") is True:
        issues.append(
            Issue(
                "error", rel,
                "ilb_config.connection_tracking sets track_per_session: true (must be false / PER_CONNECTION to avoid asymmetric state drops)"
            ))
      if ct.get("persist_conn_on_unhealthy") not in (None, "NEVER_PERSIST"):
        issues.append(
            Issue(
                "error", rel,
                "ilb_config.connection_tracking sets persist_conn_on_unhealthy != NEVER_PERSIST"
            ))

    # Check NCC Router Appliance config
    ra_cfg = doc.get("ncc_ra_config")
    if isinstance(ra_cfg, dict):
      bgp_cfg = doc.get("bgp_config") or {}
      if total_auto_instances > 0 and (not isinstance(bgp_cfg, dict) or
                                       not bgp_cfg.get("asn")):
        issues.append(
            Issue(
                "error", rel,
                "ncc_ra_config with auto-created instances requires bgp_config.asn on the NVA"
            ))
      seen_spoke_vpcs: set[str] = set()
      for spoke in ra_cfg.get("spokes") or []:
        if not isinstance(spoke, dict):
          continue
        snet = str(spoke.get("network") or "")
        svpc = snet.split(":", 1)[1] if snet.startswith("$networks:") else snet
        if svpc:
          if svpc in seen_spoke_vpcs:
            issues.append(
                Issue(
                    "error", rel,
                    f"ncc_ra_config declares multiple spokes for the same VPC '{svpc}'"
                ))
          seen_spoke_vpcs.add(svpc)
          nva_ra_vpcs.setdefault(nva_name, set()).add(svpc)
          if nic_vpcs and svpc not in nic_vpcs:
            issues.append(
                Issue(
                    "error", rel,
                    f"ncc_ra_config spoke references '$networks:{svpc}', but no NIC in auto_instance_config is attached to '{svpc}'"
                ))
          if svpc in nva_ilb_vpcs.get(nva_name, set()):
            issues.append(
                Issue(
                    "error", rel,
                    f"VPC '{svpc}' cannot have both an ILB forwarding rule and an NCC Router Appliance spoke for the same NVA '{nva_name}'"
                ))

  # Cloud Router interface & BGP peer consistency for NCC-RA
  for vpc_key, routers in vpc_routers.items():
    rel = f"vpcs/{vpc_key}/.config.yaml"
    for rname, rcfg in routers.items():
      if not isinstance(rcfg, dict):
        continue
      intfs = rcfg.get("interfaces") or {}
      rpolicies = rcfg.get("route_policies") or {}
      for iname, icfg in (intfs.items() if isinstance(intfs, dict) else ()):
        if not isinstance(icfg, dict):
          continue
        red = icfg.get("redundant_interface")
        if red:
          if red not in intfs:
            issues.append(
                Issue(
                    "error", rel,
                    f"router '{rname}' interface '{iname}' references redundant_interface '{red}' which is not defined on '{rname}'"
                ))
          elif isinstance(intfs.get(red),
                          dict) and intfs[red].get("redundant_interface"):
            issues.append(
                Issue(
                    "error", rel,
                    f"router '{rname}' interface '{iname}' sets redundant_interface '{red}', which is itself a secondary interface"
                ))
      for pname, pcfg in ((rcfg.get("peers") or {}).items() if isinstance(
          rcfg.get("peers"), dict) else ()):
        if not isinstance(pcfg, dict):
          continue
        if pcfg.get("interface") not in intfs:
          issues.append(
              Issue(
                  "error", rel,
                  f"router '{rname}' peer '{pname}' references unknown interface '{pcfg.get('interface')}'"
              ))
        for pol_field in ("import_policies", "export_policies"):
          for pol_name in pcfg.get(pol_field) or []:
            if pol_name not in rpolicies:
              issues.append(
                  Issue(
                      "error", rel,
                      f"router '{rname}' peer '{pname}' references unknown route policy '{pol_name}' in {pol_field}"
                  ))
        target_nva = pcfg.get("nva")
        if target_nva is not None:
          if target_nva not in nva_docs:
            issues.append(
                Issue(
                    "error", rel,
                    f"router '{rname}' peer '{pname}' references unknown NVA '{target_nva}'"
                ))
          elif vpc_key not in nva_ra_vpcs.get(target_nva, set()):
            issues.append(
                Issue(
                    "error", rel,
                    f"router '{rname}' peer '{pname}' targets NVA '{target_nva}', which has no ncc_ra_config spoke in VPC '{vpc_key}'"
                ))
        if pcfg.get("asn") is not None and rcfg.get("asn") == pcfg.get("asn"):
          issues.append(
              Issue(
                  "error", rel,
                  f"router '{rname}' and peer '{pname}' share ASN {pcfg.get('asn')} (Router Appliance BGP requires eBGP with distinct ASNs)"
              ))

  # Project-scoped & VPC-scoped firewall rule name uniqueness
  default_vpc_proj = str(
      ((defaults_doc.get("vpcs") or {}).get("defaults") or
       {}).get("project_id") or "") if isinstance(defaults_doc, dict) else ""
  fw_rule_owners: dict[tuple[str, str], tuple[str, str]] = {}
  for rel, doc in docs.items():
    m_fw = re.match(r"^vpcs/(.+)/firewall-rules/.+\.yaml$", rel)
    if not m_fw or not isinstance(doc, dict):
      continue
    vpc_key = m_fw.group(1)
    proj_id = str((vpc_configs.get(vpc_key) or {}).get("project_id") or
                  default_vpc_proj)
    owner_scope = proj_id or f"vpc:{vpc_key}"
    for direction in ("ingress", "egress"):
      for rule_name in (doc.get(direction) or {}):
        rk = (owner_scope, str(rule_name))
        if rk in fw_rule_owners:
          prev_vpc, prev_rel = fw_rule_owners[rk]
          issues.append(
              Issue(
                  "error", rel,
                  f"duplicate firewall rule name '{rule_name}' in project '{owner_scope}' (also defined in VPC '{prev_vpc}' at {prev_rel})"
              ))
        fw_rule_owners.setdefault(rk, (vpc_key, rel))

  # Symbolic `$token` resolution check
  for rel, ns, key in all_tokens:
    if ns in known:
      if key in known[ns]:
        continue
      if ns in EXTERNAL_CONTEXT_NAMESPACES:
        continue
      if ns == "project_ids" and (allow_external_projects or
                                  not has_project_files):
        continue
      issues.append(
          Issue(
              "error", rel,
              f"unresolved token '${ns}:{key}' (not defined in dataset; available in '{ns}': {sorted(known[ns])})"
          ))
    elif ns not in EXTERNAL_CONTEXT_NAMESPACES:
      issues.append(
          Issue("warn", rel, f"unrecognized token namespace '${ns}:{key}'"))

  return issues, {"docs": docs, "tokens": all_tokens}


def build_mock_tfvars(
    dataset_dir: pathlib.Path,
    all_tokens: list[tuple[str, str, str]],
    known_projects: set[str] | None = None,
) -> dict[str, Any]:
  """Construct synthetic FAST root variables so `terraform validate` and `plan` run offline."""
  tfvars: dict[str, Any] = json.loads(json.dumps(DUMMY_FAST_VARS))
  tfvars["factories_config"] = {
      "dataset": str(dataset_dir.resolve()),
  }
  folders = {
      "networking": "folders/12345678",
      "networking/prod": "folders/23456789",
      "networking/dev": "folders/34567890",
  }
  tags = {
      "environment/development": "tagValues/12345",
      "environment/production": "tagValues/12346",
  }
  tag_keys: dict[str, str] = {}
  sec_profiles: dict[str, str] = {}
  custom_roles: dict[str, str] = {}
  iam_principals: dict[str, str] = {}
  kms_keys: dict[str, str] = {}
  perimeters: dict[str, str] = {}
  project_ids: dict[str, str] = {}
  email_addresses: dict[str, str] = {}

  for idx, (_, ns, key) in enumerate(all_tokens):
    if ns == "folder_ids":
      folders.setdefault(key, f"folders/{40000000 + idx}")
    elif ns == "tag_values":
      tags.setdefault(key, f"tagValues/{20000 + idx}")
    elif ns == "tag_keys":
      tag_keys.setdefault(key, f"tagKeys/{30000 + idx}")
    elif ns == "security_profile_groups":
      sec_profiles.setdefault(
          key,
          f"organizations/123456789012/locations/global/securityProfileGroups/{key}"
      )
    elif ns == "custom_roles":
      custom_roles.setdefault(
          key, f"organizations/123456789012/roles/{key.replace('/', '_')}")
    elif ns == "iam_principals":
      if key.startswith("service_accounts/"):
        sa_key = key[len("service_accounts/"):]
        tfvars["service_accounts"].setdefault(
            sa_key, f"sa-{idx}@test.iam.gserviceaccount.com")
      else:
        iam_principals.setdefault(key, f"group:{key}@fast.example.com")
    elif ns == "kms_keys":
      kms_keys.setdefault(
          key, f"projects/test/locations/global/keyRings/kr/cryptoKeys/{key}")
    elif ns == "vpc_sc_perimeters":
      perimeters.setdefault(key,
                            f"accessPolicies/123456/servicePerimeters/{key}")
    elif ns == "email_addresses":
      email_addresses.setdefault(key, f"{key}@fast.example.com")
    elif ns == "storage_buckets":
      tfvars["storage_buckets"].setdefault(key, f"test-bucket-{idx}")
    elif ns == "project_ids":
      if known_projects is None or key not in known_projects:
        project_ids.setdefault(key, f"fast-{key}")

  tfvars["folder_ids"] = folders
  tfvars["tag_values"] = tags
  if tag_keys:
    tfvars["tag_keys"] = tag_keys
  if sec_profiles:
    tfvars["security_profile_groups"] = sec_profiles
  if custom_roles:
    tfvars["custom_roles"] = custom_roles
  if iam_principals:
    tfvars["iam_principals"] = iam_principals
  if kms_keys:
    tfvars["kms_keys"] = kms_keys
  if perimeters:
    tfvars["perimeters"] = perimeters
  if project_ids:
    tfvars["project_ids"] = project_ids
  if email_addresses:
    tfvars["context"] = {"email_addresses": email_addresses}
  return tfvars


def run_terraform_checks(
    dataset_dir: pathlib.Path,
    stage_dir: pathlib.Path,
    all_tokens: list[tuple[str, str, str]],
    run_plan: bool = True,
    terraform_bin: str = "terraform",
) -> tuple[list[Issue], dict[str, Any]]:
  """Run isolated `terraform init -backend=false`, `validate`, and `plan -refresh=false`."""
  issues: list[Issue] = []
  tf_path = shutil.which(terraform_bin)
  if not tf_path:
    issues.append(
        Issue("error", "terraform",
              f"'{terraform_bin}' binary not found in PATH"))
    return issues, {"ran": False}

  fabric_root = stage_dir.parents[2]
  tf_env = dict(os.environ)
  if "TF_PLUGIN_CACHE_DIR" not in tf_env:
    cache_dir = pathlib.Path.home() / ".terraform.d" / "plugin-cache"
    cache_dir.mkdir(parents=True, exist_ok=True)
    tf_env["TF_PLUGIN_CACHE_DIR"] = str(cache_dir)
  tf_env["TF_IN_AUTOMATION"] = "1"

  def ignore_stage_files(_src: str, names: list[str]) -> list[str]:
    return [
        n for n in names
        if n in (".terraform", "datasets") or n.endswith(".tfstate")
    ]

  with tempfile.TemporaryDirectory(prefix="fast-net-validate-") as tmp:
    tmp_root = pathlib.Path(tmp)
    (tmp_root / "modules").symlink_to(fabric_root / "modules")
    work = tmp_root / "fast" / "stages" / "2-networking"
    work.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(stage_dir, work, dirs_exist_ok=True,
                    ignore=ignore_stage_files)

    known_projs = {
        p.stem for p in list(dataset_dir.glob("projects/**/*.yaml")) + [
            f for f in dataset_dir.glob("folders/**/*.yaml")
            if f.name != ".config.yaml"
        ]
    }
    tfvars = build_mock_tfvars(dataset_dir, all_tokens, known_projs)
    (work / "validate.auto.tfvars.json").write_text(
        json.dumps(tfvars, indent=2), encoding="utf-8")

    steps: list[tuple[str, list[str]]] = [
        ("init",
         [tf_path, "init", "-backend=false", "-input=false", "-no-color"]),
        ("validate", [tf_path, "validate", "-no-color"]),
    ]
    if run_plan:
      steps.append((
          "plan",
          [
              tf_path, "plan", "-refresh=false", "-input=false", "-lock=false",
              "-no-color"
          ],
      ))

    summary: dict[str, Any] = {"ran": True}
    for step_name, cmd in steps:
      proc = subprocess.run(cmd, cwd=work, env=tf_env, capture_output=True,
                            text=True, check=False)
      out = (proc.stdout or "") + "\n" + (proc.stderr or "")
      if proc.returncode != 0:
        issues.append(
            Issue("error", f"terraform:{step_name}",
                  out.strip()[-2000:]))
        summary[step_name] = "failed"
        break
      summary[step_name] = "passed"
      if step_name == "plan":
        m = re.search(r"Plan: (\d+) to add, (\d+) to change, (\d+) to destroy",
                      out)
        if m:
          summary["plan_counts"] = {
              "add": int(m.group(1)),
              "change": int(m.group(2)),
              "destroy": int(m.group(3)),
          }

    return issues, summary


def main(argv: list[str] | None = None) -> int:
  parser = argparse.ArgumentParser(
      description=
      "Validate a FAST 2-networking dataset (JSON schemas, $tokens, CIDRs, guardrails, and terraform validate/plan)."
  )
  parser.add_argument("dataset_dir", type=pathlib.Path,
                      help="Path to the FAST 2-networking dataset directory.")
  parser.add_argument(
      "--stage-dir", default=None, help=
      "Optional path to fast/stages/2-networking (auto-discovered by default).")
  parser.add_argument(
      "--allow-external-projects", action="store_true", help=
      "Allow $project_ids:<key> tokens that are supplied via tfvars rather than projects/*.yaml."
  )
  parser.add_argument(
      "--no-terraform", action="store_true",
      help="Skip running `terraform init`, `validate`, and `plan`.")
  parser.add_argument(
      "--no-plan", action="store_true",
      help="Run `terraform validate` only and skip `terraform plan`.")
  parser.add_argument("--json", action="store_true",
                      help="Emit machine-readable JSON output.")
  args = parser.parse_args(argv)

  dataset_dir = args.dataset_dir.expanduser().resolve()
  if not dataset_dir.is_dir():
    print(f"ERROR: Dataset directory not found: {dataset_dir}", file=sys.stderr)
    return 2

  stage_dir = discover_stage_dir(args.stage_dir)
  issues, meta = validate_dataset_files(
      dataset_dir,
      stage_dir,
      allow_external_projects=args.allow_external_projects,
  )

  tf_summary: dict[str, Any] = {"ran": False}
  has_errors = any(i.level == "error" for i in issues)
  if not args.no_terraform and not has_errors:
    tf_issues, tf_summary = run_terraform_checks(
        dataset_dir,
        stage_dir,
        meta.get("tokens") or [],
        run_plan=not args.no_plan,
    )
    issues.extend(tf_issues)

  errors = [i.to_dict() for i in issues if i.level == "error"]
  warnings = [i.to_dict() for i in issues if i.level == "warn"]
  passed = len(errors) == 0

  if args.json:
    print(
        json.dumps(
            {
                "passed": passed,
                "dataset_dir": str(dataset_dir),
                "stage_dir": str(stage_dir),
                "error_count": len(errors),
                "warning_count": len(warnings),
                "errors": errors,
                "warnings": warnings,
                "terraform": tf_summary,
            },
            indent=2,
        ))
  else:
    status = "PASSED" if passed else "FAILED"
    print(
        f"[{status}] {dataset_dir} ({len(errors)} errors, {len(warnings)} warnings)"
    )
    if tf_summary.get("ran"):
      counts = tf_summary.get("plan_counts")
      count_str = f" (Plan: {counts['add']} to add)" if counts else ""
      print(
          f"  Terraform: init={tf_summary.get('init')} validate={tf_summary.get('validate')} plan={tf_summary.get('plan', 'skipped')}{count_str}"
      )
    for err in errors:
      print(f"  ERROR [{err['location']}]: {err['message']}")
    for warn in warnings:
      print(f"  WARN  [{warn['location']}]: {warn['message']}")

  return 0 if passed else 1


if __name__ == "__main__":
  sys.exit(main())
