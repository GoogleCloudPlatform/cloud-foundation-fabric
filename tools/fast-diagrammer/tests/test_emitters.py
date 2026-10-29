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
"""Emitter gates: escaping, ids, the .drawio twin, icons and snapshots.

Scenes are assembled from the model dataclasses directly (not through the
builder helpers) so the emitters are tested as the last line of defence.
"""

import base64
import html
import json
import re
import xml.etree.ElementTree as ET

import pytest

from fast_diagrammer.scene.emit_drawio import (build_drawio_model,
                                               decompress_diagram)
from fast_diagrammer.scene.model import (Badge, CardNode, EdgeSpec, LegendEntry,
                                         SceneGraph, ZoneNode)
from fast_diagrammer.scene.render import load_icons, render_scene
from fast_diagrammer.scene.serialize import (SceneFormatError, dumps_scene,
                                             loads_scene, scene_from_dict,
                                             scene_to_dict)

SVG_NS = "{http://www.w3.org/2000/svg}"
XLINK_HREF = "{http://www.w3.org/1999/xlink}href"
CELL_ID = re.compile(r"[A-Za-z0-9_]+")
SVG_ID = re.compile(r"[A-Za-z0-9_-]+")
# The only markup the draw.io emitter itself writes into html=1 labels.
OWN_TAGS = re.compile(r"</?(?:b|br|font)(?: [^<>]*)?>")

HOSTILE = [
    "a<b",
    "a&b",
    "a&amp;b",
    'a"b',
    "a'b",
    "x]]>y",
    "<script>alert(1)</script>",
    "<img src=x onerror=alert(1)>",
    "a;b",
    "k=v;fillColor=#ff0000;",
    "a=b",
    "50%",
    "%3Cb%3E",
    "line1\nline2",
    "tab\there",
    "\x00nul",
    "\x01ctl\x1f",
    "\ufffe",
    "🚀 emoji",
    "עברית rtl",
]
FIELDS = ("ds", "view", "stage", "ztitle", "zsub", "zbadge", "ctitle", "csub",
          "cbadge", "icon", "elabel", "color", "fill", "legend")
# Fields whose text is drawn verbatim (modulo control characters).
TEXT_FIELDS = ("ztitle", "zsub", "ctitle", "elabel", "legend")


@pytest.fixture(scope="module")
def icons():
  return load_icons()


def _scene(**over) -> SceneGraph:

  def v(key, default):
    return over.get(key, default)

  s = SceneGraph(v("ds", "ds"), v("view", "topology"),
                 stage=v("stage", "2-networking"))
  root = ZoneNode("root", title=v("ztitle", "Root"), subtitle=v("zsub", "Sub"),
                  style_name="@ArchitectureRoot", icon="GoogleCloud",
                  badges=[Badge(v("zbadge", "zb"), "warn")])
  zone = ZoneNode("z", title=v("ztitle", "Zone"),
                  subtitle=v("zsub", "Zone sub"), style_name="@ProjectZone",
                  layout="row", icon="Project", parent_zone_id="root")
  c1 = CardNode(v("id", "c1"), v("ctitle", "Card one"), v("csub", "sub one"),
                icon=v("icon", "CloudRouter"), fill=v("fill", "#ffffff"),
                stroke_color=v("color", "#dadce0"), parent_zone_id="z",
                badges=[Badge(v("cbadge", "b1"), "info")])
  c2 = CardNode("c2", "Card two", "sub two", icon="ComputeEngine",
                parent_zone_id="z", dashed=True)
  root.children = [zone]
  zone.children = [c1, c2]
  s.root_zones = [root]
  s.zones = {"root": root, "z": zone}
  s.cards = {c1.id: c1, "c2": c2}
  s.edges = [
      EdgeSpec(c1.id, "c2", "<-->", v("elabel", "link"), v("color", "#1a73e8")),
      EdgeSpec("c2", c1.id, "-.->", v("elabel", "back"), "#d55e00",
               dash="dotted", head="open"),
  ]
  s.legend = [
      LegendEntry(v("legend", "edge row"), "edge", color=v("color", "#1a73e8"),
                  head="filled"),
      LegendEntry(v("legend", "card row"), "card", fill=v("fill", "#ffffff"),
                  color=v("color", "#5f6368"), dashed=True),
  ]
  return s


def _parse_outputs(res):
  """(svg root, standalone mxfile root, mxGraphModel decoded from content=)."""
  svg = ET.fromstring(res.svg.encode("utf-8"))
  drawio = ET.fromstring(res.drawio.encode("utf-8"))
  embedded = ET.fromstring(svg.get("content").encode("utf-8"))
  assert embedded.tag == "mxfile"
  diagram = embedded.find("diagram")
  model = ET.fromstring(decompress_diagram(diagram.text).encode("utf-8"))
  return svg, drawio, model


def _style(cell) -> dict:
  out = {}
  for part in (cell.get("style") or "").split(";"):
    if part:
      key, _, val = part.partition("=")
      assert key not in out, f"duplicate style key {key} in {cell.get('id')}"
      out[key] = val
  return out


def _label_text(value: str) -> str:
  """Visible text of an html=1 label, as diagrams.net would render it."""
  return html.unescape(OWN_TAGS.sub(" ", value))


def _clean(text: str) -> str:
  return re.sub("[\x00-\x08\x0b\x0c\x0e-\x1f\ufffe\uffff]", "", text)


def _xml_norm(text: str) -> str:
  # Attribute-value normalisation turns tab/LF/CR into spaces.
  return re.sub(r"[\t\n\r]", " ", text)


@pytest.mark.parametrize("evil", HOSTILE, ids=repr)
@pytest.mark.parametrize("field", FIELDS)
def test_hostile_strings(field, evil, icons):
  baseline = render_scene(_scene(), icons, check_overlaps=False)
  _, base_drawio, _ = _parse_outputs(baseline)
  allowed_keys = {k for c in base_drawio.iter("mxCell") for k in _style(c)}

  res = render_scene(_scene(**{field: evil}), icons, check_overlaps=False)
  svg, drawio, model = _parse_outputs(res)

  # The SVG's embedded mxfile is the same document as the .drawio.
  assert [ET.tostring(c) for c in model.iter("mxCell")
         ] == [ET.tostring(c) for c in drawio.iter("mxCell")]
  for text in (res.svg, res.drawio):
    assert not re.search("[\x00-\x08\x0b\x0c\x0e-\x1f]", text)

  for cell in drawio.iter("mxCell"):
    for attr in ("id", "parent", "source", "target"):
      if cell.get(attr) is not None:
        assert CELL_ID.fullmatch(cell.get(attr)), (attr, cell.get(attr))
    style = _style(cell)
    assert set(style) <= allowed_keys, set(style) - allowed_keys
    if style.get("html") == "1":
      leftover = OWN_TAGS.sub("", cell.get("value") or "")
      assert "<" not in leftover and ">" not in leftover, (cell.get("id"),
                                                           leftover)

  for el in svg.iter():
    if el.get("id") is not None:
      assert SVG_ID.fullmatch(el.get("id")), el.get("id")
    for attr in ("marker-start", "marker-end", "filter"):
      if el.get(attr) is not None:
        assert re.fullmatch(r"url\(#[A-Za-z0-9_-]+\)", el.get(attr))
    if el.get(XLINK_HREF) is not None:
      assert re.fullmatch(r"#icon-[A-Za-z0-9_-]+", el.get(XLINK_HREF))
  # No markup from the dataset reaches the SVG either.
  assert not svg.findall(f".//{SVG_NS}script")
  assert not svg.findall(f".//{SVG_NS}img")

  if field in TEXT_FIELDS and _clean(evil):
    svg_text = " ".join(t.text or "" for t in svg.iter(f"{SVG_NS}text"))
    assert _clean(evil) in svg_text
    labels = " ".join(
        _label_text(c.get("value") or "") for c in drawio.iter("mxCell"))
    assert _xml_norm(_clean(evil)) in labels


@pytest.mark.parametrize("bad_id", ["a<b", 'a"b', "a-b", "a b", "café", ""])
def test_unsafe_element_ids_are_rejected(bad_id, icons):
  with pytest.raises(ValueError, match=r"\[A-Za-z0-9_\]\+"):
    render_scene(_scene(id=bad_id), icons, check_overlaps=False)


def test_drawio_carries_icons_and_zone_subtitles(icons):
  scene = _scene(icon="NoSuchIcon")
  res = render_scene(scene, icons, check_overlaps=False)
  _, drawio, _ = _parse_outputs(res)
  cells = {c.get("id"): c for c in drawio.iter("mxCell")}
  expected = {
      "card_c1": "CloudGeneric",  # unknown icons fall back, as in the SVG
      "card_c2": "ComputeEngine",
      "zone_root": "GoogleCloud",
      "zone_z": "Project",
  }
  for owner, name in expected.items():
    icon = cells[f"icon_{owner}"]
    assert icon.get("parent") == owner and icon.get("vertex") == "1"
    style = _style(icon)
    assert style["shape"] == "image" and style["connectable"] == "0"
    prefix = "data:image/svg+xml,"
    assert style["image"].startswith(prefix), style["image"][:40]
    glyph = ET.fromstring(base64.b64decode(style["image"][len(prefix):]))
    assert glyph.tag == f"{SVG_NS}svg"
    assert glyph.get("viewBox") == icons[name]["viewBox"]
  # No literal "[IconName]" placeholders survive in labels.
  assert not re.search(r"\[(?:Cloud|Compute|Google)\w*\]", res.drawio)
  for zid in ("root", "z"):
    zone = scene.zones[zid]
    value = _label_text(cells[f"zone_{zid}"].get("value"))
    assert zone.title in value and zone.subtitle in value
    assert _style(cells[f"zone_{zid}"])["startSize"] == "48"


def test_svg_icons_are_symbols(icons):
  res = render_scene(_scene(), icons, check_overlaps=False)
  svg = ET.fromstring(res.svg.encode("utf-8"))
  assert svg.get("role") == "img"
  first = [el.tag for el in svg][:2]
  assert first == [f"{SVG_NS}title", f"{SVG_NS}desc"]
  assert svg.find(f"{SVG_NS}title").text == "ds (topology)"
  assert "fast-diagrammer" in svg.find(f"{SVG_NS}desc").text
  symbols = svg.findall(f"{SVG_NS}defs/{SVG_NS}symbol")
  ids = [s.get("id") for s in symbols]
  assert ids == sorted(set(ids))
  assert set(ids) == {
      "icon-CloudRouter", "icon-ComputeEngine", "icon-GoogleCloud",
      "icon-Project"
  }
  uses = svg.findall(f"{SVG_NS}use")
  assert len(uses) == 4
  assert {u.get(XLINK_HREF)[1:] for u in uses} == set(ids)
  # Only the root <svg>: icons are no longer inlined as nested documents.
  assert len(list(svg.iter(f"{SVG_NS}svg"))) == 1


def test_marker_ids_for_non_hex_colours(icons):
  scene = _scene(color="a<b")
  scene.edges.append(EdgeSpec("c2", "c1", "-->", "x", "a>b"))
  res = render_scene(scene, icons, check_overlaps=False)
  svg = ET.fromstring(res.svg.encode("utf-8"))
  ids = [m.get("id") for m in svg.iter(f"{SVG_NS}marker")]
  assert len(ids) == len(set(ids))
  ends = sorted(i for i in ids if i.startswith("arrow-end-"))
  assert len(ends) == 3  # "a<b", "a>b", "#d55e00" (legend reuses "a<b")
  hex_res = render_scene(_scene(), icons, check_overlaps=False)
  assert '<marker id="arrow-end-1a73e8"' in hex_res.svg


def test_mxfile_header_is_fixed(icons):
  a = render_scene(_scene(), icons, check_overlaps=False)
  b = render_scene(_scene(), icons, check_overlaps=False)
  assert a.drawio == b.drawio and a.svg == b.svg
  head = ET.fromstring(a.drawio.encode("utf-8"))
  assert head.get("agent") == "fast-diagrammer"
  assert head.get("modified") == "2026-10-28T12:00:00.000Z"


def test_cell_ids_are_unique(icons):
  # Derived icon cells cannot collide with element ids such as `c1_icon`.
  scene = _scene()
  extra = CardNode("c1_icon", "Clash", "sub", icon="CloudNAT",
                   parent_zone_id="z")
  scene.zones["z"].children.append(extra)
  scene.cards[extra.id] = extra
  res = render_scene(scene, icons, check_overlaps=False)
  ids = [c.get("id") for c in ET.fromstring(res.drawio).iter("mxCell")]
  assert len(ids) == len(set(ids))
  assert {"card_c1", "icon_card_c1", "card_c1_icon",
          "icon_card_c1_icon"} <= set(ids)
  # Two nodes with one id are refused by the emitter itself, even when the
  # scene skipped validation (layout is already done here).
  dup = CardNode("c2", "Again", "sub", parent_zone_id="z")
  scene.zones["z"].children.append(dup)
  with pytest.raises(ValueError, match="duplicate diagram cell id 'card_c2'"):
    build_drawio_model(scene, {}, {}, None, icons)


def _snapshot():
  return scene_to_dict(_scene())


@pytest.mark.parametrize(
    "mutate,where",
    [
        (lambda d: d.pop("dataset_name"), "snapshot: missing field"),
        (lambda d: d.update(root_zones={}), "root_zones: expected a list"),
        (lambda d: d["root_zones"][0].update(kind="box"),
         r"root_zones\[0\]: kind must be"),
        (lambda d: d["root_zones"][0]["children"][0]["children"][0].pop(
            "title"), r"root_zones\[0\].children\[0\].children\[0\]: missing"),
        (lambda d: d["root_zones"][0].update(badges=[{
            "text": "x",
            "bogus": 1
        }]), r"root_zones\[0\].badges\[0\]"),
        (lambda d: d["root_zones"][0].update(id="a<b"),
         r"root_zones\[0\]: id 'a<b'"),
        (lambda d: d["edges"][0].update(src=7), r"edges\[0\].src"),
        (lambda d: d["edges"][0].update(extra=1), r"edges\[0\]"),
        (lambda d: d["edges"].append("nope"),
         r"edges\[2\]: expected an object"),
        (lambda d: d.update(legend=[None]), r"legend\[0\]"),
    ],
)
def test_scene_from_dict_format_errors(mutate, where):
  data = _snapshot()
  mutate(data)
  with pytest.raises(SceneFormatError, match=where):
    scene_from_dict(data)


def test_scene_snapshot_errors_are_value_errors():
  for text in ("[]", "not json", json.dumps({"format": "other"})):
    with pytest.raises(SceneFormatError):
      loads_scene(text)
  assert issubclass(SceneFormatError, ValueError)
  # A well-formed snapshot still round-trips.
  text = dumps_scene(_scene())
  assert dumps_scene(loads_scene(text)) == text
