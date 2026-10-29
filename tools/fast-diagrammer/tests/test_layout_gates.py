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
"""Core-engine gates: golden integrity, engine parity, no-overlap, determinism,
dependency leakage, boilerplate, icon registry, multi-stage rendering, stage
detection, YAML/token helpers and the CLI.

Every mechanical detector here is paired with a known-bad input that must
make it fire, so a detector that silently stops working fails the suite.
"""

import ast
import hashlib
import json
import pathlib
import re
import sys
import xml.etree.ElementTree as ET

import pytest

from conftest import (APP_ROOT, GOLDEN_DIR, GOLDEN_EXPECTED, GOLDEN_INPUTS,
                      canonical_svg, GOLDEN_KEYS, golden_scene,
                      missing_dataset_reason, require_dataset,
                      stage_datasets_root)
from fast_diagrammer import tokens, yamlio
from fast_diagrammer.datasets.base import (Dataset, StageDetectionError,
                                           detect_stage)
from fast_diagrammer.scene import render as render_mod
from fast_diagrammer.scene.layout import layout_scene
from fast_diagrammer.scene.model import (GCP_ICONS, Badge, LegendEntry,
                                         SceneGraph, make_card, make_edge,
                                         make_zone, resolve_color)
from fast_diagrammer.scene.render import OverlapError, load_icons, render_scene
from fast_diagrammer.scene.router import (route_all_edges,
                                          verify_no_arrow_overlaps)

PACKAGE_DIR = APP_ROOT / "fast_diagrammer"
LEGACY_ICONS_SHA256 = (
    "ea67443a77128eb063e0e6e325e12ba9a3bd0d631b3256dd123a4186bbd4a0f7")


def _golden_scene(key):
  return golden_scene(key)


def _matches_golden_svg(svg: bytes, key: str) -> bool:
  """Byte equality with `expected/<key>.drawio.svg`, `content=` inflated."""
  return canonical_svg(svg) == canonical_svg(
      (GOLDEN_EXPECTED / f"{key}.drawio.svg").read_bytes())


# --------------------------------------------------------------------------
# Golden integrity and engine parity (12/12)
# --------------------------------------------------------------------------


def _sha256sums_mismatches(base: pathlib.Path):
  bad = []
  for line in (base / "SHA256SUMS").read_text().splitlines():
    digest, rel = line.split("  ", 1)
    path = base / rel
    if not path.is_file() or hashlib.sha256(
        path.read_bytes()).hexdigest() != digest:
      bad.append(rel)
  return bad


def test_golden_set_is_complete():
  assert len(GOLDEN_KEYS) == 12
  for key in GOLDEN_KEYS:
    assert (GOLDEN_INPUTS / f"{key}.scene.json").is_file(), key
    assert (GOLDEN_EXPECTED / f"{key}.drawio").is_file(), key
    assert (GOLDEN_EXPECTED / f"{key}.drawio.svg").is_file(), key


def test_golden_sha256sums_match():
  assert _sha256sums_mismatches(GOLDEN_DIR) == []


def test_golden_sha256sums_negative_control(tmp_path):
  """A one-byte change to a golden copy must be caught by the checksum gate."""
  base = tmp_path / "g"
  (base / "expected").mkdir(parents=True)
  (base / "inputs").mkdir()
  key = GOLDEN_KEYS[0]
  for rel in (f"expected/{key}.drawio", f"inputs/{key}.scene.json"):
    data = bytearray((GOLDEN_DIR / rel).read_bytes())
    if rel.endswith(".drawio"):
      data[100] ^= 0x01
    (base / rel).write_bytes(bytes(data))
  lines = [
      l for l in (GOLDEN_DIR / "SHA256SUMS").read_text().splitlines()
      if l.endswith(f"/{key}.drawio") or l.endswith(f"/{key}.scene.json")
  ]
  (base / "SHA256SUMS").write_text("\n".join(lines) + "\n")
  assert _sha256sums_mismatches(base) == [f"expected/{key}.drawio"]


@pytest.mark.parametrize("key", GOLDEN_KEYS)
def test_engine_byte_parity(key, icons_map):
  result = render_scene(_golden_scene(key), icons_map)
  assert result.drawio.encode("utf-8") == (GOLDEN_EXPECTED /
                                           f"{key}.drawio").read_bytes()
  assert _matches_golden_svg(result.svg.encode("utf-8"), key)


def test_engine_parity_negative_control(icons_map):
  """Perturbing one card width must change the rendered bytes."""
  key = "hub-and-spokes-ncc-topology"
  scene = _golden_scene(key)
  next(iter(scene.cards.values())).width += 1.0
  result = render_scene(scene, icons_map)
  assert not _matches_golden_svg(result.svg.encode("utf-8"), key)


def test_render_writes_files(tmp_path, icons_map):
  key = GOLDEN_KEYS[0]
  render_mod.render(_golden_scene(key), icons_map, tmp_path / "x.drawio.svg",
                    tmp_path / "x.drawio")
  assert (tmp_path / "x.drawio").read_bytes() == (GOLDEN_EXPECTED /
                                                  f"{key}.drawio").read_bytes()
  assert _matches_golden_svg((tmp_path / "x.drawio.svg").read_bytes(), key)


# --------------------------------------------------------------------------
# Determinism and overlap gate
# --------------------------------------------------------------------------


@pytest.mark.parametrize("key", GOLDEN_KEYS)
def test_render_twice_is_deterministic(key, icons_map):
  a = render_scene(_golden_scene(key), icons_map)
  b = render_scene(_golden_scene(key), icons_map)
  assert a.svg == b.svg and a.drawio == b.drawio


@pytest.mark.parametrize("key", GOLDEN_KEYS)
def test_goldens_have_no_arrow_overlaps(key):
  scene = _golden_scene(key)
  layout_scene(scene)
  _, polylines, _ = route_all_edges(scene)
  assert verify_no_arrow_overlaps(polylines) == []


def test_overlap_gate_flags_vertical_overlap():
  polylines = {
      0: [(0, 0), (50, 0), (50, 100)],
      1: [(10, 20), (52, 20), (52, 90)]
  }
  errs = verify_no_arrow_overlaps(polylines)
  assert errs and "Vertical overlap" in errs[0]


def test_overlap_gate_flags_horizontal_overlap():
  """Horizontal overlaps are reported, not only vertical ones."""
  polylines = {
      0: [(0, 0), (0, 40), (100, 40)],
      1: [(20, 80), (20, 42), (90, 42)]
  }
  errs = verify_no_arrow_overlaps(polylines)
  assert errs and "Horizontal overlap" in errs[0]


def test_overlap_gate_accepts_clean_routes():
  polylines = {
      0: [(0, 0), (0, 40), (100, 40)],
      1: [(0, 80), (0, 60), (100, 60)]
  }
  assert verify_no_arrow_overlaps(polylines) == []


def test_render_raises_on_overlap(monkeypatch, icons_map):
  scene = _golden_scene(GOLDEN_KEYS[0])
  real = render_mod.route_all_edges

  def bad_router(s):
    ports, _, labels = real(s)
    return ports, {
        0: [(0, 0), (0, 40), (100, 40)],
        1: [(20, 80), (20, 42), (90, 42)]
    }, labels

  monkeypatch.setattr(render_mod, "route_all_edges", bad_router)
  with pytest.raises(OverlapError):
    render_scene(scene, icons_map)
  scene = _golden_scene(GOLDEN_KEYS[0])
  res = render_scene(scene, icons_map, check_overlaps=False)
  assert res.overlap_errors


# --------------------------------------------------------------------------
# Dependency leakage and boilerplate
# --------------------------------------------------------------------------

ALLOWED_THIRD_PARTY = {"yaml"}


def _non_stdlib_imports(root: pathlib.Path):
  bad = []
  for p in sorted(root.rglob("*.py")):
    tree = ast.parse(p.read_text(encoding="utf-8"))
    for node in ast.walk(tree):
      names = []
      if isinstance(node, ast.Import):
        names = [a.name for a in node.names]
      elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
        names = [node.module]
      for n in names:
        top = n.split(".")[0]
        if (top not in sys.stdlib_module_names and
            top not in ALLOWED_THIRD_PARTY and top != "fast_diagrammer"):
          bad.append(f"{p.relative_to(root).as_posix()}: {n}")
  return bad


def test_package_imports_only_stdlib_and_yaml():
  assert _non_stdlib_imports(PACKAGE_DIR) == []


def test_dependency_gates_negative_control(tmp_path):
  (tmp_path /
   "bad.py").write_text("import requests\nfrom ruamel.yaml import YAML\n")
  assert _non_stdlib_imports(tmp_path) == [
      "bad.py: requests", "bad.py: ruamel.yaml"
  ]


APACHE_RE = re.compile(
    r"^(#![^\n]*\n)?# Copyright 20\d\d Google LLC\n#\n"
    r"# Licensed under the Apache License, Version 2\.0 \(the \"License\"\);\n")


def _missing_boilerplate(root: pathlib.Path):
  missing = []
  for p in sorted(list(root.rglob("*.py")) + list(root.rglob("*.sh"))):
    rel = p.relative_to(root)
    if "__pycache__" in rel.parts:
      continue
    if not APACHE_RE.match(p.read_text(encoding="utf-8")):
      missing.append(rel.as_posix())
  return missing


def test_apache_boilerplate_everywhere():
  assert _missing_boilerplate(APP_ROOT) == []


def test_boilerplate_negative_control(tmp_path):
  (tmp_path / "ok.py").write_text(
      (PACKAGE_DIR / "__init__.py").read_text(encoding="utf-8"))
  (tmp_path / "bad.sh").write_text("#!/bin/bash\necho no header\n")
  assert _missing_boilerplate(tmp_path) == ["bad.sh"]


# --------------------------------------------------------------------------
# Icon registry
# --------------------------------------------------------------------------

LEGACY = ("GoogleCloud", "VirtualPrivateCloud", "NetworkConnectivityCenter",
          "CloudVPN", "CloudInterconnect", "CloudRouter", "CloudNAT",
          "CloudDNS", "LoadBalancing", "ComputeEngine", "CloudGeneric",
          "Networking", "Server")


def _legacy_digest(icons):
  return hashlib.sha256(
      json.dumps([[n, icons[n]] for n in LEGACY],
                 sort_keys=True).encode()).hexdigest()


def test_legacy_icons_are_pinned(icons_map):
  assert list(icons_map)[:13] == list(LEGACY)
  assert _legacy_digest(icons_map) == LEGACY_ICONS_SHA256


def test_legacy_icon_pin_negative_control(icons_map):
  mutated = dict(icons_map)
  mutated["CloudVPN"] = dict(mutated["CloudVPN"],
                             inner=mutated["CloudVPN"]["inner"] + " ")
  assert _legacy_digest(mutated) != LEGACY_ICONS_SHA256


def test_registry_icons_all_present(icons_map):
  missing = [n for n in GCP_ICONS if n not in icons_map]
  assert missing == []
  for n in GCP_ICONS:
    assert (PACKAGE_DIR / "icons" / GCP_ICONS[n].file).is_file(), n


def test_icons_json_is_fresh():
  sys.path.insert(0, str(APP_ROOT / "tools"))
  import build_icons  # pylint: disable=import-outside-toplevel
  assert build_icons.build() == (PACKAGE_DIR / "icons" /
                                 "icons.json").read_text(encoding="utf-8")


def test_new_icons_are_well_formed(icons_map):
  for n in GCP_ICONS:
    if n in LEGACY:
      continue
    ET.fromstring(
        f'<svg xmlns="http://www.w3.org/2000/svg">{icons_map[n]["inner"]}</svg>'
    )
    x, y, w, h = (float(v) for v in icons_map[n]["viewBox"].split())
    assert w == h, n


# --------------------------------------------------------------------------
# Multi-stage rendering features (badges, dashes, heads, grid, legend)
# --------------------------------------------------------------------------


def _feature_scene():
  sc = SceneGraph("demo", "hierarchy", stage="0-org-setup")
  org = sc.add_zone(
      make_zone(
          "org", "@OrganizationZone", "Organization · example.com", "org 1",
          badges=[Badge("36 org policies"),
                  Badge("9 custom roles", "info")]))
  grid = sc.add_zone(
      make_zone("f", "@FolderZone", "Teams", layout="grid", max_cols=2), org)
  for i in range(3):
    sc.add_card(
        make_card(
            f"p{i}", f"p-{i}", f"proj-{i}", "@ProjectCard", badges=[
                Badge("Shared VPC host", "info"),
                Badge("SA: 3"),
                Badge("KMS: ew1/logging", "warn"),
                Badge("CMEK", "warn"),
                Badge("GCS: 4 buckets"),
                Badge("BQ: billing_export", "info"),
                Badge("CI/CD: github", "ok")
            ]), grid)
  col = sc.add_zone(make_zone("c", "@SubGroupWhite", "Root"), org)
  sc.add_card(
      make_card("set", "Resource set: x", "stage-generated",
                "@ResourceSetCard"), col)
  sc.add_card(make_card("ext", "Any external (*)", "egress", "@ExternalCard"),
              col)
  sc.add_edge(
      make_edge("p0", "ext", label="egress", color="$VermilionStroke",
                dash="dashed", head="open"))
  sc.add_edge(
      make_edge("set", "p1", label="binding", color="$TealStroke",
                dash="dotted", head="none"))
  sc.legend = [
      LegendEntry("ingress", color="#1a73e8"),
      LegendEntry("egress", color="#d55e00", dash="dashed", head="open"),
      LegendEntry("log sink", color="#007b83", dash="dashdot"),
      LegendEntry("symbolic set", kind="card", color="#5f6368", dashed=True),
  ]
  return sc


def test_feature_scene_renders_and_is_deterministic():
  icons = load_icons()
  a = render_scene(_feature_scene(), icons)
  b = render_scene(_feature_scene(), icons)
  assert a.svg == b.svg and a.drawio == b.drawio
  assert a.overlap_errors == [] and a.unknown_icons == []
  ET.fromstring(a.svg.encode("utf-8"))
  ET.fromstring(a.drawio.encode("utf-8"))


def test_feature_scene_semantics():
  scene = _feature_scene()
  res = render_scene(scene, load_icons())
  svg, drawio = res.svg, res.drawio
  # Badges grow cards, overflow collapses to "+N", zone badges are drawn.
  assert scene.cards["p0"].height > 58.0
  assert re.search(r">\+\d+</text>", svg)
  assert ">36 org policies</text>" in svg
  # Dashed symbolic-set card border, open / no heads, dash vocabulary.
  assert 'stroke="#5f6368" stroke-width="1.5" stroke-dasharray="5 3"' in svg
  assert 'marker-end="url(#arrow-open-d55e00)"' in svg
  assert '<marker id="arrow-open-d55e00"' in svg
  assert 'stroke-dasharray="2 3" />' in svg  # dotted edge with head="none"
  assert 'stroke-dasharray="8 3 2 3"' in svg  # legend dashdot sample
  assert "endArrow=open;endFill=0;" in drawio and "endArrow=none;" in drawio
  assert "dashPattern=2 3;" in drawio
  # Grid: 3 cards in max_cols=2 -> two rows.
  ys = sorted({round(scene.cards[f"p{i}"].y, 1) for i in range(3)})
  assert len(ys) == 2
  # Legend sits below all zones and inside the canvas.
  assert ">Legend</text>" in svg and 'id="legend"' in drawio
  bottom = max(z.y + z.h for z in scene.zones.values())
  m = re.search(
      r'<mxCell id="legend".*?<mxGeometry x="([\d.]+)" y="([\d.]+)" '
      r'width="([\d.]+)" height="([\d.]+)"', drawio, re.S)
  assert m and float(m.group(2)) > bottom
  assert float(m.group(2)) + float(m.group(4)) < res.height


def legend_errors(scene):
  """Edge legend rows vs the edge styles drawn: every drawn (colour, dash,
  head) has exactly one legend row, and every row matches a drawn edge."""
  drawn = {(resolve_color(e.color), e.dash_style, e.head) for e in scene.edges}
  rows = [(l.color, l.dash, l.head) for l in scene.legend if l.kind == "edge"]
  errs = [f"legend row {r} matches no edge" for r in rows if r not in drawn]
  errs += [
      f"edge style {d} missing from the legend" for d in sorted(drawn)
      if d not in rows
  ]
  errs += [
      f"legend rows share style {r}"
      for r in sorted({r for r in rows if rows.count(r) > 1})
  ]
  return errs


@pytest.mark.parametrize("key", GOLDEN_KEYS)
def test_golden_legends_match_drawn_edges(key):
  scene = _golden_scene(key)
  assert scene.legend, key
  assert legend_errors(scene) == []


def test_legend_errors_negative_control():
  scene = _golden_scene("hub-and-spokes-nva-ncc-topology")
  e = scene.edges[0]
  style = (resolve_color(e.color), e.dash_style, e.head)
  # A drawn style without a row, a row without an edge, a duplicated row.
  scene.legend = [l for l in scene.legend if (l.color, l.dash, l.head) != style]
  scene.legend.append(LegendEntry("bogus", color="#000000", dash="dotted"))
  scene.legend.append(scene.legend[0])
  errs = legend_errors(scene)
  assert any("missing from the legend" in e for e in errs), errs
  assert any("matches no edge" in e for e in errs), errs
  assert any("share style" in e for e in errs), errs


@pytest.mark.parametrize("key", GOLDEN_KEYS)
def test_networking_goldens_use_no_badges_or_grids(key):
  """2-networking draws concrete resources: no badge pills, no grid zones,
  no dashed (symbolic) cards; those belong to stages whose data has them."""
  scene = _golden_scene(key)
  assert all(not c.badges and not c.dashed for c in scene.cards.values())
  assert all(not z.badges and z.layout != "grid" for z in scene.zones.values())


def test_unknown_icons_reported_not_fatal(icons_map):
  scene = _feature_scene()
  scene.cards["p0"].icon = "NoSuchIcon"
  res = render_scene(scene, icons_map)
  assert res.unknown_icons == ["NoSuchIcon"]
  assert res.overlap_errors == []
  ET.fromstring(res.svg.encode("utf-8"))
  assert render_scene(_feature_scene(), icons_map).unknown_icons == []


# --------------------------------------------------------------------------
# Stage detection
# --------------------------------------------------------------------------


@pytest.mark.parametrize("layout,stage", [
    (["perimeters/"], "1-vpcsc"),
    (["restricted-services.yaml"], "1-vpcsc"),
    (["organization/", "vpcs/"], "0-org-setup"),
    (["organization/", "folders/"], "0-org-setup"),
    (["vpcs/", "ncc-hubs/"], "2-networking"),
    (["vpcs/", "nvas/"], "2-networking"),
    (["folders/", "projects/", "vpcs/", "ncc-hubs/"], "2-networking"),
])
def test_detect_stage_fingerprints(tmp_path, layout, stage):
  for entry in layout:
    if entry.endswith("/"):
      (tmp_path / entry).mkdir()
    else:
      (tmp_path / entry).write_text("{}\n")
  assert detect_stage(tmp_path) == stage
  assert Dataset.from_path(tmp_path).stage == stage


def test_detect_stage_rejects_unknown(tmp_path):
  (tmp_path / "random.yaml").write_text("{}\n")
  with pytest.raises(StageDetectionError, match="random.yaml"):
    detect_stage(tmp_path)


@pytest.mark.parametrize("layout",
                         [["folders/"], ["vpcs/"], ["folders/", "projects/"]])
def test_detect_stage_rejects_ambiguous_layouts(tmp_path, layout):
  """`folders/` or a bare `vpcs/` also appear in unsupported stages."""
  for entry in layout:
    (tmp_path / entry).mkdir()
  with pytest.raises(StageDetectionError):
    detect_stage(tmp_path)


@pytest.mark.parametrize("stage", ["0-org-setup", "1-vpcsc", "2-networking"])
def test_detect_stage_on_fabric_datasets(stage):
  root = stage_datasets_root(stage)
  if root is None:
    pytest.skip(missing_dataset_reason(stage, "*"))
  dirs = [p for p in root.iterdir() if p.is_dir() and not p.is_symlink()]
  assert dirs
  for d in dirs:
    assert detect_stage(d) == stage, d.name


# --------------------------------------------------------------------------
# YAML and tokens
# --------------------------------------------------------------------------


def test_yamlio_yaml12_semantics():
  # Plain yes/no/on/off stay strings, with a warning because Terraform's
  # yamldecode would read them as booleans.
  with pytest.warns(yamlio.DatasetWarning) as record:
    doc = yamlio.loads("a: no\nb: on\nc: 1:20\nd: 2026-01-01\ne: true\n"
                       "f: 0o17\ng: 012\nh: 1.5\ni: ~\nregions: [ES, NO, IT]\n")
  assert sorted(
      str(w.message).split("'")[1] for w in record) == ["NO", "no", "on"]
  assert doc == {
      "a": "no",
      "b": "on",
      "c": "1:20",
      "d": "2026-01-01",
      "e": True,
      "f": 15,
      "g": 12,
      "h": 1.5,
      "i": None,
      "regions": ["ES", "NO", "IT"]
  }
  assert yamlio.loads("") == {}
  assert list(yamlio.loads("z: 1\na: 2\n")) == ["z", "a"]


def test_yamlio_file_helpers(tmp_path):
  (tmp_path / "b.yaml").write_text("x: 1\n")
  (tmp_path / "a.yml").write_text("")
  (tmp_path / ".config.yaml").write_text("h: 1\n")
  (tmp_path / "sub").mkdir()
  (tmp_path / "sub" / "c.yaml").write_text("y: 2\n")
  (tmp_path / ".hidden").mkdir()
  (tmp_path / ".hidden" / "d.yaml").write_text("z: 3\n")
  (tmp_path / "e.yaml").write_text("")
  # Like Terraform `fileset(dir, "*.yaml")`: `.yml` files are not read.
  assert [p.name for p in yamlio.yaml_files(tmp_path)] == ["b.yaml", "e.yaml"]
  assert [p.name for p in yamlio.yaml_files(tmp_path, include_hidden=True)
         ] == [".config.yaml", "b.yaml", "e.yaml"]
  assert [
      p.relative_to(tmp_path).as_posix() for p in yamlio.rglob_yaml(tmp_path)
  ] == ["b.yaml", "e.yaml", "sub/c.yaml"]
  assert yamlio.load(tmp_path / "e.yaml") == {}
  assert yamlio.load_or_empty(tmp_path / "missing.yaml") == {}
  assert yamlio.yaml_files(tmp_path / "missing") == []
  assert list(yamlio.iter_docs(tmp_path)) == [("b", {"x": 1}), ("e", {})]


def test_tokens():
  assert tokens.parse("$networks:hub") == ("networks", "hub")
  assert tokens.parse("networks:hub") is None and tokens.parse(3) is None
  assert tokens.key_of("$project_ids:net-0", "project_ids") == "net-0"
  assert tokens.key_of("$project_ids:net-0", "networks") is None
  assert tokens.split_path("a/b/c", 3) == ["a", "b", "c"]
  assert tokens.split_path("a/b", 3) is None
  assert tokens.router("hub", "r1") == "$routers:hub/r1"
  assert tokens.format_token("resource_sets", "x") == "$resource_sets:x"


# --------------------------------------------------------------------------
# 2-networking invariants on the direct builder: containment, view
# semantics, closest-side anchors
# --------------------------------------------------------------------------

NET_DATASETS = ("hub-and-spokes-ncc", "hub-and-spokes-nva",
                "hub-and-spokes-nva-ncc", "hub-and-spokes-peerings",
                "hub-and-spokes-vpns")


def _net_scene(name, view, **kw):
  from fast_diagrammer.stages import networking  # pylint: disable=import-outside-toplevel
  d = require_dataset("2-networking", name)
  return networking.build(d, view, dataset_name=name, **kw)


def _style_chain(scene, zid):
  out = []
  while zid:
    z = scene.zones[zid]
    out.append(z.style_name)
    zid = z.parent_zone_id
  return out


def containment_errors(scene):
  """Cards sit in Project/External zones, VPCs in Projects, sites outside."""
  errs = []
  for c in scene.cards.values():
    if not {"@ProjectZone", "@ExternalZone"} & set(
        _style_chain(scene, c.parent_zone_id)):
      errs.append(f"card {c.id} outside any Project/External zone")
  for z in scene.zones.values():
    chain = _style_chain(scene, z.parent_zone_id)
    if z.style_name == "@VpcZone" and "@ProjectZone" not in chain:
      errs.append(f"VPC zone {z.id} outside a Project zone")
    if z.style_name == "@ExternalZone" and "@ArchitectureRoot" in chain:
      errs.append(f"external zone {z.id} inside the Google Cloud root")
  return errs


def semantics_errors(topo, dns):
  """Topology has routers but no subnet/DNS cards; DNS bind edges are dashed,
  peer/forward edges solid."""
  errs = []
  icons = {c.icon for c in topo.cards.values()}
  if icons & {"Subnet", "CloudDNS"}:
    errs.append("topology contains Subnet/CloudDNS cards")
  if "CloudRouter" not in icons:
    errs.append("topology has no CloudRouter card")
  for e in dns.edges:
    if e.label.startswith("Bind") and not (e.dashed and e.arrow == "-.->"):
      errs.append(f"Bind edge {e.src}->{e.dst} is not dashed")
    if e.label.startswith(
        ("Peer", "Forward")) and (e.dashed or e.arrow != "-->"):
      errs.append(f"{e.label} edge {e.src}->{e.dst} is not solid")
  return errs


def anchor_errors(scene):
  """Cross-column edges leave/enter on the facing horizontal sides."""
  errs = []
  for e in scene.edges:
    s, t = scene.cards.get(e.src), scene.cards.get(e.dst)
    if not s or not t:
      continue
    if s.x + s.width + 10.0 < t.x and (e.source_anchor,
                                       e.target_anchor) != ("right", "left"):
      errs.append(f"{e.src}->{e.dst}: expected right->left")
    if t.x + t.width + 10.0 < s.x and (e.source_anchor,
                                       e.target_anchor) != ("left", "right"):
      errs.append(f"{e.src}->{e.dst}: expected left->right")
  return errs


@pytest.mark.parametrize("name", NET_DATASETS)
@pytest.mark.parametrize("view", ["topology", "dns"])
def test_networking_containment(name, view):
  assert containment_errors(_net_scene(name, view)) == []


def test_networking_containment_negative_control():
  scene = _net_scene("hub-and-spokes-nva", "topology")
  card = next(c for c in scene.cards.values()
              if "@VpcZone" in _style_chain(scene, c.parent_zone_id))
  card.parent_zone_id = "GoogleCloudRoot"
  vpc = next(z for z in scene.zones.values() if z.style_name == "@VpcZone")
  vpc.parent_zone_id = "GoogleCloudRoot"
  errs = containment_errors(scene)
  assert any(card.id in e for e in errs) and any(vpc.id in e for e in errs)


@pytest.mark.parametrize("name", NET_DATASETS)
def test_networking_topology_and_dns_semantics(name):
  assert semantics_errors(_net_scene(name, "topology"),
                          _net_scene(name, "dns")) == []


def test_networking_semantics_negative_control():
  topo = _net_scene("hub-and-spokes-nva", "topology")
  dns = _net_scene("hub-and-spokes-nva", "dns")
  bind = next(e for e in dns.edges if e.label.startswith("Bind"))
  bind.dashed, bind.arrow = False, "-->"
  peer_or_fwd = next(
      e for e in dns.edges if e.label.startswith(("Peer", "Forward")))
  peer_or_fwd.dashed = True
  next(iter(topo.cards.values())).icon = "CloudDNS"
  errs = semantics_errors(topo, dns)
  assert len(errs) == 3, errs


def test_networking_rpz_bind_lines_toggle():
  plain = _net_scene("hub-and-spokes-ncc", "dns")
  rpz = _net_scene("hub-and-spokes-ncc", "dns", rpz_bind_lines=True)
  assert not any(e.label == "Bind (RPZ)" for e in plain.edges)
  assert any(e.label == "Bind (RPZ)" and e.dashed for e in rpz.edges)


@pytest.mark.parametrize("name", NET_DATASETS)
@pytest.mark.parametrize("view", ["topology", "dns"])
def test_networking_closest_side_anchors(name, view):
  scene = _net_scene(name, view)
  layout_scene(scene)
  assert anchor_errors(scene) == []


def test_networking_anchor_negative_control():
  scene = _net_scene("hub-and-spokes-nva", "topology")
  layout_scene(scene)
  e = next(e for e in scene.edges
           if (e.source_anchor, e.target_anchor) in (("right", "left"),
                                                     ("left", "right")))
  e.source_anchor, e.target_anchor = e.target_anchor, e.source_anchor
  assert anchor_errors(scene)


# --------------------------------------------------------------------------
# Multi-stage routing: zone endpoints, zone obstacles, card auto-width
# --------------------------------------------------------------------------


def _zone_scene(stage):
  """A ─ [Project P header] ─ B in one start-aligned row: A→B crosses P's header."""
  sc = SceneGraph("z", "hierarchy", stage=stage)
  root = sc.add_zone(
      make_zone("root", "@Ghost", layout="row", align="start", gap=60))
  sc.add_card(make_card("a", "A", "src"), root)
  p = sc.add_zone(make_zone("P", "@ProjectZone", "Project: p", "prod-p"), root)
  sc.add_card(make_card("inner", "Log buckets", "audit-logs"), p)
  sc.add_card(make_card("b", "B", "dst"), root)
  sc.add_edge(make_edge("a", "b", label="a to b"))
  return sc


def _segments_hit_box(pts, box, pad=1.0):
  x1, y1, x2, y2 = box
  for (ax, ay), (bx, by) in zip(pts, pts[1:]):
    if (max(ax, bx) > x1 + pad and min(ax, bx) < x2 - pad and
        max(ay, by) > y1 + pad and min(ay, by) < y2 - pad):
      return True
  return False


def test_multistage_edges_route_around_unrelated_zones():
  sc = _zone_scene("0-org-setup")
  res = render_scene(sc, load_icons())
  p = sc.zones["P"]
  assert not _segments_hit_box(res.polylines[0],
                               (p.x, p.y, p.x + p.w, p.y + p.h))


def test_zone_obstacle_negative_control():
  """Without a stage (networking semantics) the same edge cuts through P."""
  sc = _zone_scene("")
  res = render_scene(sc, load_icons())
  p = sc.zones["P"]
  assert _segments_hit_box(res.polylines[0], (p.x, p.y, p.x + p.w, p.y + p.h))


def test_edge_can_target_a_zone():
  sc = _zone_scene("0-org-setup")
  sc.edges[0] = make_edge("a", "P", label="parent")
  res = render_scene(sc, load_icons())
  p = sc.zones["P"]
  last = res.polylines[0][-1]
  assert abs(last[0] - p.x) < 0.01 and p.y <= last[1] <= p.y + p.h
  assert 'source="card_a" target="zone_P"' in res.drawio
  assert res.overlap_errors == []


def test_multistage_cards_widen_to_fit_text():
  long_sub = "subnets: default 10.0.0.0/24 (primary) and 3 ingress firewall rules"
  for stage, grows in (("0-org-setup", True), ("2-networking", False), ("",
                                                                        False)):
    sc = SceneGraph("w", "hierarchy", stage=stage)
    z = sc.add_zone(make_zone("z", "@SubGroupWhite", "Z"))
    sc.add_card(make_card("c", "VPC: dev-shared-0", long_sub, "@ProjectCard"),
                z)
    layout_scene(sc)
    assert (sc.cards["c"].width > 236.0) is grows, stage


def test_multistage_inner_segments_avoid_fixed_stubs():
  """Regression (org-setup classic): a bridge must not sit on another edge's stub."""
  from fast_diagrammer.scene.router import _stub_segments  # pylint: disable=import-outside-toplevel
  stubs = _stub_segments(
      {
          0: [(0, 10), (50, 10), (50, 90), (100, 90)],
          1: [(5, 0), (5, 40), (60, 40), (60, 80)]
      }, horizontal=True)
  assert stubs == [(10, 0, 50), (90, 50, 100)]
  vstubs = _stub_segments({1: [(5, 0), (5, 40), (60, 40), (60, 80)]},
                          horizontal=False)
  assert vstubs == [(5, 0, 40), (60, 40, 80)]


def _tree_scene(stage="0-org-setup"):
  """Org on top, a folder tier in the middle, a project row at the bottom."""
  sc = SceneGraph("t", "hierarchy", stage=stage)
  col = sc.add_zone(make_zone("col", "@Ghost", gap=70))
  top = sc.add_zone(make_zone("top", "@Ghost", layout="row"), col)
  sc.add_card(make_card("org", "Organization", "id: 1"), top)
  mid = sc.add_zone(
      make_zone("mid", "@Ghost", layout="row", align="start", gap=60), col)
  sc.add_card(make_card("f1", "Folder: A", "a"), mid)
  sc.add_card(make_card("f2", "Folder: B", "b"), mid)
  bot = sc.add_zone(
      make_zone("bot", "@Ghost", layout="row", align="start", gap=60), col)
  p = sc.add_zone(make_zone("P", "@ProjectZone", "Project: p", "prod-p"), bot)
  sc.add_card(make_card("inner", "Log Buckets", "3"), p)
  for dst in ("f1", "f2", "P"):
    sc.add_edge(
        make_edge("org", dst, source_anchor="bottom", target_anchor="top"))
  return sc


def test_multistage_tree_edges_keep_vertical_anchors_and_avoid_tiers():
  sc = _tree_scene()
  res = render_scene(sc, load_icons())
  assert all(
      (e.source_anchor, e.target_anchor) == ("bottom", "top") for e in sc.edges)
  assert res.overlap_errors == []
  for i, e in enumerate(sc.edges):
    for oid in ("f1", "f2"):
      if oid == e.dst:
        continue
      c = sc.cards[oid]
      assert not _segments_hit_box(
          res.polylines[i],
          (c.x, c.y, c.x + c.width, c.y + c.height)), (e.dst, oid)
  # The org -> project edge ends on the zone's top border, fork bar 20 px above.
  pts = res.polylines[2]
  assert abs(pts[-1][1] -
             sc.zones["P"].y) < 0.01 and abs(pts[-2][1] -
                                             (pts[-1][1] - 20.0)) < 0.01


def test_tree_route_negative_control():
  """Networking semantics (no stage) keep the halfway fork bar, inside the folder tier."""
  sc = _tree_scene(stage="")
  res = render_scene(sc, load_icons(), check_overlaps=False)
  pts = res.polylines[2]
  org, p = sc.cards["org"], sc.zones["P"]
  assert len(pts) == 4
  assert abs(pts[1][1] - (org.y + org.height + p.y) / 2.0) < 0.01
  f = sc.cards["f1"]
  assert f.y < pts[1][1] < f.y + f.height  # the bar runs through the middle tier


def test_clear_z_channel_and_inner_range():
  from fast_diagrammer.scene.router import _clear_z_channel, _inner_range  # pylint: disable=import-outside-toplevel
  blocker = make_card("blk", "x", "")
  blocker.x, blocker.y, blocker.width, blocker.height = 140.0, 0.0, 40.0, 60.0
  # Midpoint channel (160) is blocked; sx + 28 = 128 is free.
  assert _clear_z_channel(100.0, 30.0, 220.0, 120.0, "right", {"blk": blocker},
                          ("", "")) == 128.0
  assert _clear_z_channel(100.0, 30.0, 220.0, 120.0, "right", {},
                          ("", "")) == 160.0
  assert _inner_range([(0, 0), (0, 50), (90, 50), (90, 100)], 1,
                      axis=1) == (8.0, 92.0)
  lo, hi = _inner_range([(0, 50), (20, 50), (20, -30), (90, -30), (90, 60),
                         (100, 60)], 2, axis=1)
  assert lo == float("-inf") and hi == float(
      "inf")  # bridge bars are free to move


def test_row_gap_floor_is_networking_only():
  for stage, expected in (("0-org-setup", 20.0), ("", 56.0), ("2-networking",
                                                              56.0)):
    sc = SceneGraph("g", "hierarchy", stage=stage)
    row = sc.add_zone(make_zone("r", "@Ghost", layout="row", gap=20))
    sc.add_card(make_card("a", "A", "a"), row)
    sc.add_card(make_card("b", "B", "b"), row)
    layout_scene(sc)
    assert sc.zones["r"].gap == expected, stage


# --------------------------------------------------------------------------
# CLI: input forms, entry scripts, options, exit codes, error handling
# --------------------------------------------------------------------------

NVA_NCC = "hub-and-spokes-nva-ncc"


def _cli(argv):
  from fast_diagrammer import cli  # pylint: disable=import-outside-toplevel
  return cli.run([str(a) for a in argv])


def _tree(root: pathlib.Path):
  return sorted(p.relative_to(root).as_posix() for p in root.rglob("*"))


@pytest.fixture(scope="module")
def nva_ncc(tmp_path_factory):
  """`(dataset_dir, reference_dir)`: the dataset rendered by the builder
  directly, without the CLI, which every CLI input form must reproduce."""
  from fast_diagrammer.stages import networking  # pylint: disable=import-outside-toplevel
  ds = require_dataset("2-networking", NVA_NCC)
  ref = tmp_path_factory.mktemp("reference")
  icons = load_icons()
  for view in networking.VIEWS:
    scene = networking.build(ds, view, dataset_name=NVA_NCC)
    scene.stage = scene.stage or "2-networking"
    render_mod.render(scene, icons, ref / f"{NVA_NCC}-{view}.drawio.svg",
                      ref / f"{NVA_NCC}-{view}.drawio")
  return ds, ref


def _assert_reference_outputs(out_dir, ref_dir):
  expected = sorted(p.name for p in ref_dir.iterdir())
  assert sorted(p.name for p in out_dir.iterdir()) == expected
  for name in expected:
    assert (out_dir / name).read_bytes() == (ref_dir / name).read_bytes(), name


def _tiny_vpcsc(root: pathlib.Path, unresolved: bool = False) -> pathlib.Path:
  """Minimal 1-vpcsc dataset; `unresolved` adds an unknown `$resource_sets`."""
  (root / "perimeters").mkdir(parents=True)
  (root / "defaults.yaml").write_text(
      "context:\n  resource_sets:\n    static_set:\n      - projects/111\n")
  (root / "restricted-services.yaml").write_text("- storage.googleapis.com\n")
  extra = "    - $resource_sets:mystery_unknown\n" if unresolved else ""
  (root / "perimeters" / "default.yaml").write_text(
      "status:\n  resources:\n    - $resource_sets:static_set\n" + extra +
      "  restricted_services:\n    - $service_sets:restricted_services\n")
  return root


def test_stage_aliases():
  import argparse  # pylint: disable=import-outside-toplevel
  from fast_diagrammer.cli import stage_type  # pylint: disable=import-outside-toplevel
  assert [
      stage_type(a) for a in ("org-setup", "org", "VPC-SC", "vpc_sc", "net",
                              "networking", "auto", "1-vpcsc")
  ] == [
      "0-org-setup", "0-org-setup", "1-vpcsc", "1-vpcsc", "2-networking",
      "2-networking", "auto", "1-vpcsc"
  ]
  with pytest.raises(argparse.ArgumentTypeError):
    stage_type("security")


def test_cli_renders_dataset_and_never_writes_inputs(tmp_path, nva_ncc):
  ds, ref = nva_ncc
  before = _tree(ds)
  assert _cli(["--dataset", ds, "--out-dir", tmp_path / "out"]) == 0
  _assert_reference_outputs(tmp_path / "out", ref)
  assert _tree(ds) == before


def test_cli_positional_input_type_alias_and_short_out(tmp_path, nva_ncc):
  ds, ref = nva_ncc
  assert _cli([ds, "-t", "net", "-o", tmp_path / "a"]) == 0
  _assert_reference_outputs(tmp_path / "a", ref)
  assert _cli(["-i", ds, "--stage", "networking", tmp_path / "b"]) == 0
  _assert_reference_outputs(tmp_path / "b", ref)


def test_cli_smart_stage_and_datasets_folders(tmp_path, nva_ncc):
  import shutil  # pylint: disable=import-outside-toplevel
  ds, ref = nva_ncc
  stage_dir = tmp_path / "2-networking"
  shutil.copytree(ds, stage_dir / "datasets" / NVA_NCC)
  (stage_dir / "datasets" / "notes").mkdir()  # not a dataset: skipped
  assert _cli([stage_dir, tmp_path / "s"]) == 0
  _assert_reference_outputs(tmp_path / "s", ref)
  assert _cli(["--dataset", stage_dir / "datasets", "-o", tmp_path / "d"]) == 0
  _assert_reference_outputs(tmp_path / "d", ref)


def test_cli_fast_root_uses_stage_dir_names(tmp_path, nva_ncc):
  """A project-factory dataset with `folders/` must not render as org-setup."""
  import shutil  # pylint: disable=import-outside-toplevel
  ds, ref = nva_ncc
  stages = tmp_path / "stages"
  shutil.copytree(ds, stages / "2-networking" / "datasets" / NVA_NCC)
  (stages / "2-project-factory" / "datasets" / "classic" /
   "folders").mkdir(parents=True)
  out = tmp_path / "out"
  assert _cli(["--fast-root", stages, "--out-dir", out]) == 0
  assert sorted(p.relative_to(out).as_posix() for p in out.rglob("*")) == [
      "2-networking", "2-networking/" + f"{NVA_NCC}-dns.drawio",
      "2-networking/" + f"{NVA_NCC}-dns.drawio.svg",
      "2-networking/" + f"{NVA_NCC}-topology.drawio",
      "2-networking/" + f"{NVA_NCC}-topology.drawio.svg"
  ]
  _assert_reference_outputs(out / "2-networking", ref)


def test_cli_input_and_output_validation(tmp_path, nva_ncc):
  ds = str(nva_ncc[0])
  for argv in ([ds], [ds, "--dataset", ds, "-o",
                      tmp_path], [ds, tmp_path, "-o",
                                  tmp_path], ["-o", tmp_path]):
    with pytest.raises(SystemExit) as exc:
      _cli(argv)
    assert exc.value.code == 2, argv


@pytest.mark.parametrize("entry", ["dir", "script"])
def test_entry_scripts(tmp_path, entry, nva_ncc):
  import subprocess  # pylint: disable=import-outside-toplevel
  ds, ref = nva_ncc
  target = APP_ROOT if entry == "dir" else APP_ROOT / "fast_diagrammer.py"
  proc = subprocess.run([
      sys.executable, "-B",
      str(target),
      str(ds), "-t", "net", "-o",
      str(tmp_path / "out")
  ], cwd=tmp_path, capture_output=True, text=True, timeout=120)
  assert proc.returncode == 0, proc.stderr
  _assert_reference_outputs(tmp_path / "out", ref)


def test_cli_help_lists_every_option(capsys):
  with pytest.raises(SystemExit) as exc:
    _cli(["--help"])
  assert exc.value.code == 0
  out = capsys.readouterr().out
  assert out.startswith("usage: fast-diagrammer ")
  for flag in ("--input", "--dataset", "--datasets-root", "--fast-root",
               "--out-dir", "--type", "--views", "--org-dataset",
               "--cicd-workflows", "--verbose-badges", "--legend",
               "--no-legend", "--rasterizer", "--rpz-bind-lines", "--strict"):
    assert flag in out, flag


def test_cli_missing_input_is_a_usage_error(tmp_path, capsys):
  ds = _tiny_vpcsc(tmp_path / "vpcsc")
  missing = tmp_path / "missing"
  for argv in ([missing, "-o",
                tmp_path / "a"], [missing, "-t", "net", "-o", tmp_path / "a"],
               ["--fast-root", missing, "-o",
                tmp_path / "a"], ["-i", missing, tmp_path / "a"],
               [ds, "-o", tmp_path / "a", "--org-dataset", missing]):
    with pytest.raises(SystemExit) as exc:
      _cli(argv)
    assert exc.value.code == 2, argv
    assert "is not an existing directory" in capsys.readouterr().err
  assert not (tmp_path / "a").exists()


def test_cli_rejects_unknown_dataset(tmp_path, capsys):
  bad = tmp_path / "bad"
  bad.mkdir()
  (bad / "x.yaml").write_text("{}\n")
  assert _cli(["--dataset", bad, "--out-dir", tmp_path / "out"]) == 1
  assert "cannot detect FAST stage" in capsys.readouterr().err
  assert not (tmp_path / "out").exists()


def test_cli_views_subset_and_unknown_views(tmp_path, capsys, nva_ncc):
  ds, _ = nva_ncc
  assert _cli([ds, "-o", tmp_path / "v", "--views", "dns"]) == 0
  assert sorted(p.name for p in (tmp_path / "v").iterdir()) == [
      f"{NVA_NCC}-dns.drawio", f"{NVA_NCC}-dns.drawio.svg"
  ]
  capsys.readouterr()
  with pytest.raises(SystemExit) as exc:
    _cli([ds, "-o", tmp_path / "bad", "--views", "dns,bogus"])
  assert exc.value.code == 2
  err = capsys.readouterr().err
  assert "unknown view(s) bogus" in err and "2-networking: topology, dns" in err
  assert not (tmp_path / "bad").exists()


def test_cli_nothing_rendered_exits_2(tmp_path, capsys):
  stage_dir = tmp_path / "2-security"
  (stage_dir / "datasets" / "classic" / "keyrings").mkdir(parents=True)
  assert _cli([stage_dir, "-o", tmp_path / "out"]) == 2
  err = capsys.readouterr().err
  assert "[skip] cannot detect FAST stage" in err
  assert "[error] no diagrams rendered" in err
  (tmp_path / "empty" / "datasets").mkdir(parents=True)
  assert _cli([tmp_path / "empty", "-o", tmp_path / "out"]) == 2
  assert "[error] no datasets found" in capsys.readouterr().err


def test_cli_strict_exit_codes(tmp_path, capsys):
  ds = _tiny_vpcsc(tmp_path / "vpcsc", unresolved=True)
  assert _cli([ds, "-o", tmp_path / "lax"]) == 0
  assert (tmp_path / "lax" / "vpcsc-perimeters.drawio.svg").is_file()
  capsys.readouterr()
  assert _cli([ds, "-o", tmp_path / "strict", "--strict"]) == 1
  captured = capsys.readouterr()
  assert "[FAIL] 1-vpcsc/vpcsc-perimeters" in captured.err
  assert "Unresolved symbolic references" in captured.err
  assert "0 diagram(s) rendered, 1 failure(s)" in captured.out


def test_cli_strict_unknown_icons(tmp_path, capsys, monkeypatch):
  import dataclasses  # pylint: disable=import-outside-toplevel
  from fast_diagrammer import cli  # pylint: disable=import-outside-toplevel
  real = cli.render

  def render_with_unknown_icon(*args, **kwargs):
    return dataclasses.replace(real(*args, **kwargs), unknown_icons=["Bogus"])

  monkeypatch.setattr(cli, "render", render_with_unknown_icon)
  ds = _tiny_vpcsc(tmp_path / "vpcsc")
  assert _cli([ds, "-o", tmp_path / "lax"]) == 0
  assert "[warn] 1-vpcsc/vpcsc-perimeters: unknown icons ['Bogus']" in (
      capsys.readouterr().err)
  assert _cli([ds, "-o", tmp_path / "strict", "--strict"]) == 1
  assert "[FAIL] 1-vpcsc/vpcsc-perimeters: unknown icons" in (
      capsys.readouterr().err)


def test_cli_dataset_warnings_are_warn_lines(tmp_path, capsys):
  ds = _tiny_vpcsc(tmp_path / "vpcsc")
  with (ds / "defaults.yaml").open("a") as f:
    f.write("unquoted: no\n")  # Terraform would read a boolean here
  assert _cli([ds, "-o", tmp_path / "out"]) == 0
  warns = [
      l for l in capsys.readouterr().err.splitlines()
      if l.startswith("[warn] 1-vpcsc/vpcsc: ")
  ]
  assert len(warns) == 1 and "defaults.yaml" in warns[0], warns


def test_cli_legend_toggle(tmp_path):
  ds = require_dataset("0-org-setup", "classic")
  svgs = {}
  for flag in ("", "--legend", "--no-legend"):
    out = tmp_path / (flag.strip("-") or "default")
    assert _cli([ds, "-o", out] + ([flag] if flag else [])) == 0
    svgs[flag] = (out / "classic-hierarchy.drawio.svg").read_text()
  assert ">Legend</text>" in svgs[""] and ">Legend</text>" in svgs["--legend"]
  assert ">Legend</text>" not in svgs["--no-legend"]
  with pytest.raises(SystemExit):
    _cli([ds, "-o", tmp_path / "x", "--legend", "--no-legend"])


def test_cli_verbose_badges(tmp_path):
  ds = require_dataset("0-org-setup", "classic")
  assert _cli([ds, "-o", tmp_path / "a"]) == 0
  assert _cli([ds, "-o", tmp_path / "b", "--verbose-badges"]) == 0
  plain = (tmp_path / "a" / "classic-hierarchy.drawio.svg").read_text()
  verbose = (tmp_path / "b" / "classic-hierarchy.drawio.svg").read_text()
  # The default budget hides badges that the verbose run draws.
  assert plain.count("</text>") < verbose.count("</text>")


def test_cli_org_dataset(tmp_path):
  ds = require_dataset("1-vpcsc", "classic")
  org = require_dataset("0-org-setup", "classic")
  assert _cli([ds, "-o", tmp_path / "a"]) == 0
  assert _cli([ds, "-o", tmp_path / "b", "--org-dataset", org]) == 0
  plain = (tmp_path / "a" / "classic-perimeters.drawio").read_text()
  enriched = (tmp_path / "b" / "classic-perimeters.drawio").read_text()
  assert "via --org-dataset" not in plain
  assert "via --org-dataset" in enriched


def test_cli_cicd_workflows(tmp_path, capsys):
  ds = require_dataset("0-org-setup", "classic")
  assert _cli([ds, "-o", tmp_path / "a"]) == 0
  assert _cli([ds, "-o", tmp_path / "b", "--cicd-workflows", "cicd.yaml"]) == 0
  assert "CI/CD WIF" not in (tmp_path / "a" /
                             "classic-hierarchy.drawio").read_text()
  assert "CI/CD WIF" in (tmp_path / "b" /
                         "classic-hierarchy.drawio").read_text()
  capsys.readouterr()
  vpcsc = _tiny_vpcsc(tmp_path / "vpcsc")
  assert _cli([vpcsc, "-o", tmp_path / "c", "--cicd-workflows",
               "cicd.yaml"]) == 0
  assert "[warn] --cicd-workflows only applies to 0-org-setup datasets" in (
      capsys.readouterr().err)


def _copy_rasterizer():
  code = "import shutil, sys; shutil.copy(sys.argv[1], sys.argv[2])"
  return f'"{sys.executable}" -c "{code}" {{svg}} {{png}}'


def test_cli_rasterizer(tmp_path, capsys, monkeypatch):
  monkeypatch.delenv("FD_RASTERIZER", raising=False)
  ds = _tiny_vpcsc(tmp_path / "vpcsc")
  assert _cli([ds, "-o", tmp_path / "ok", "--rasterizer",
               _copy_rasterizer()]) == 0
  assert (tmp_path / "ok" / "vpcsc-perimeters.png").read_bytes() == (
      tmp_path / "ok" / "vpcsc-perimeters.drawio.svg").read_bytes()
  capsys.readouterr()
  failing = f'"{sys.executable}" -c "raise SystemExit(3)" {{svg}} {{png}}'
  assert _cli([ds, "-o", tmp_path / "fail", "--rasterizer", failing]) == 0
  assert "[warn] rasterizer failed for vpcsc-perimeters.drawio.svg" in (
      capsys.readouterr().err)


@pytest.mark.parametrize(
    "template", ["convert {oops} {png}", "x { y", "{0}", "'unbalanced {svg}"])
def test_cli_rasterizer_bad_template_is_a_warning(tmp_path, capsys, monkeypatch,
                                                  template):
  ds = _tiny_vpcsc(tmp_path / "vpcsc")
  monkeypatch.setenv("FD_RASTERIZER", template)
  assert _cli([ds, "-o", tmp_path / "env"]) == 0
  err = capsys.readouterr().err
  assert "[warn] ignoring --rasterizer/FD_RASTERIZER template" in err
  assert "Traceback" not in err
  assert not list((tmp_path / "env").glob("*.png"))
  monkeypatch.delenv("FD_RASTERIZER")
  assert _cli([ds, "-o", tmp_path / "flag", "--rasterizer", template]) == 0
  assert "[warn] ignoring" in capsys.readouterr().err


def test_cli_type_mismatch_warns(tmp_path, capsys, nva_ncc):
  ds, _ = nva_ncc
  assert _cli([ds, "-t", "org-setup", "-o", tmp_path / "a"]) == 0
  err = capsys.readouterr().err
  assert ("looks like a 2-networking dataset, rendering as 0-org-setup "
          "because of -t/--type") in err
  assert _cli([ds, "-t", "net", "-o", tmp_path / "b"]) == 0
  assert "[warn]" not in capsys.readouterr().err
  empty = tmp_path / "empty"
  empty.mkdir()
  rc = _cli([empty, "-t", "vpc-sc", "-o", tmp_path / "c"])
  err = capsys.readouterr().err
  assert ("no FAST stage fingerprint found, rendering as 1-vpcsc because of "
          "-t/--type") in err
  assert rc in (0, 1) and "Traceback" not in err


def test_cli_symlinked_datasets(tmp_path, capsys):
  datasets = tmp_path / "stages" / "1-vpcsc" / "datasets"
  _tiny_vpcsc(datasets / "real")
  (datasets / "alias").symlink_to("real", target_is_directory=True)
  # Folder run: the real directory only, plus an explicit skip line.
  assert _cli([datasets.parent, "-o", tmp_path / "folder"]) == 0
  assert "[skip] alias -> real (symlink)" in capsys.readouterr().err
  assert sorted(p.name for p in (tmp_path / "folder").iterdir()) == [
      "real-perimeters.drawio", "real-perimeters.drawio.svg"
  ]
  # --fast-root run: same, prefixed with the stage.
  assert _cli(["--fast-root", tmp_path / "stages", "-o",
               tmp_path / "fast"]) == 0
  assert "[skip] 1-vpcsc/alias -> real (symlink)" in capsys.readouterr().err
  assert sorted(p.name for p in (tmp_path / "fast" / "1-vpcsc").iterdir()) == [
      "real-perimeters.drawio", "real-perimeters.drawio.svg"
  ]
  # Single dataset: rendered under the name that was typed.
  assert _cli([datasets / "alias", "-o", tmp_path / "single"]) == 0
  assert sorted(p.name for p in (tmp_path / "single").iterdir()) == [
      "alias-perimeters.drawio", "alias-perimeters.drawio.svg"
  ]


def test_cli_refuses_out_dir_inside_input(tmp_path, capsys):
  ds = _tiny_vpcsc(tmp_path / "vpcsc")
  before = _tree(ds)
  for out in (ds, ds / "diagrams", ds / "perimeters" / "x"):
    with pytest.raises(SystemExit) as exc:
      _cli([ds, "-o", out])
    assert exc.value.code == 2
    assert "inputs are never written" in capsys.readouterr().err
  with pytest.raises(SystemExit):
    _cli([tmp_path, "-o", ds / "out"])  # datasets folder holding the dataset
  assert _tree(ds) == before


def test_cli_output_errors_are_one_line(tmp_path, capsys):
  import os  # pylint: disable=import-outside-toplevel
  ds = _tiny_vpcsc(tmp_path / "vpcsc")
  (tmp_path / "file").write_text("x\n")
  assert _cli([ds, "-o", tmp_path / "file"]) == 1
  err = capsys.readouterr().err
  assert err.strip().splitlines() == [
      f"[error] output path {tmp_path / 'file'} exists and is not a directory"
  ]
  if os.geteuid() == 0:
    pytest.skip("root ignores directory permissions")
  locked = tmp_path / "locked"
  locked.mkdir(mode=0o500)
  try:
    assert _cli([ds, "-o", locked / "sub"]) == 1
    err = capsys.readouterr().err
    assert err.startswith("[error] cannot create output directory")
    assert "Traceback" not in err
    assert _cli([ds, "-o", locked]) == 1
    err = capsys.readouterr().err
    assert err.startswith("[error] cannot write") and "Permission denied" in err
  finally:
    locked.chmod(0o700)


def test_scene_snapshot_round_trip():
  from fast_diagrammer.scene.serialize import dumps_scene, loads_scene  # pylint: disable=import-outside-toplevel
  for key in GOLDEN_KEYS:
    text = (GOLDEN_INPUTS / f"{key}.scene.json").read_text(encoding="utf-8")
    assert dumps_scene(loads_scene(text)) == text, key
  feat = _feature_scene()
  again = loads_scene(dumps_scene(feat))
  icons = load_icons()
  assert render_scene(again, icons).svg == render_scene(_feature_scene(),
                                                        icons).svg


def test_scene_snapshot_rejects_unknown_format():
  from fast_diagrammer.scene.serialize import loads_scene  # pylint: disable=import-outside-toplevel
  with pytest.raises(ValueError):
    loads_scene('{"format": "something-else"}')
