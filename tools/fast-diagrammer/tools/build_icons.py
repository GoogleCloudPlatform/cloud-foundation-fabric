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
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Builds `fast_diagrammer/icons/icons.json` from the vendored `*.svg` files.

  uv run tools/fast-diagrammer/tools/build_icons.py            # rewrite icons.json
  uv run tools/fast-diagrammer/tools/build_icons.py --check    # exit 1 if stale

The 13 legacy entries (`LEGACY_ICONS`) are copied verbatim from the current
icons.json, never regenerated from their SVGs: their `inner` markup is part
of the byte-parity contract of the 2-networking goldens, so changing one is
a deliberate golden update. Every other `<Name>.svg` is parsed
with `xml.etree`, its viewBox normalised to a square, and its children
serialised without the SVG namespace. Output order: legacy entries, then the
`GCP_ICONS` registry order, then any remaining SVGs alphabetically.
"""

import argparse
import json
import pathlib
import sys
import xml.etree.ElementTree as ET

APP_ROOT = pathlib.Path(__file__).resolve().parent.parent
ICONS_DIR = APP_ROOT / "fast_diagrammer" / "icons"
ICONS_JSON = ICONS_DIR / "icons.json"
SVG_NS = "http://www.w3.org/2000/svg"

LEGACY_ICONS = (
    "GoogleCloud",
    "VirtualPrivateCloud",
    "NetworkConnectivityCenter",
    "CloudVPN",
    "CloudInterconnect",
    "CloudRouter",
    "CloudNAT",
    "CloudDNS",
    "LoadBalancing",
    "ComputeEngine",
    "CloudGeneric",
    "Networking",
    "Server",
)


def _fmt(v: float) -> str:
  return f"{v:.2f}".rstrip("0").rstrip(".")


def square_viewbox(view_box: str) -> str:
  """Expands a viewBox to a square, centred on the original box."""
  x, y, w, h = (float(p) for p in view_box.replace(",", " ").split())
  if abs(w - h) < 1e-9:
    return " ".join(_fmt(v) for v in (x, y, w, h))
  side = max(w, h)
  x -= (side - w) / 2.0
  y -= (side - h) / 2.0
  return " ".join(_fmt(v) for v in (x, y, side, side))


def svg_to_entry(path: pathlib.Path) -> dict:
  root = ET.fromstring(path.read_text(encoding="utf-8"))
  if root.tag not in ("svg", f"{{{SVG_NS}}}svg"):
    raise ValueError(f"{path.name}: root element is not <svg>")
  view_box = root.get("viewBox")
  if not view_box:
    w, h = root.get("width"), root.get("height")
    if not (w and h):
      raise ValueError(f"{path.name}: no viewBox and no width/height")
    view_box = f"0 0 {float(w.rstrip('px'))} {float(h.rstrip('px'))}"
  for el in root.iter():
    if isinstance(el.tag, str) and "}" in el.tag:
      el.tag = el.tag.split("}", 1)[1]
  parts = []
  for child in root:
    child.tail = None
    parts.append(ET.tostring(child, encoding="unicode"))
  if not parts:
    raise ValueError(f"{path.name}: empty icon")
  return {"viewBox": square_viewbox(view_box), "inner": "\n".join(parts)}


def build(icons_dir: pathlib.Path = ICONS_DIR,
          icons_json: pathlib.Path = ICONS_JSON) -> str:
  """Fresh icons.json text (needs `fast_diagrammer` importable)."""
  from fast_diagrammer.scene.model import GCP_ICONS  # pylint: disable=import-outside-toplevel

  current = json.loads(icons_json.read_text(encoding="utf-8"))
  out = {}
  for name in LEGACY_ICONS:
    if name not in current:
      raise SystemExit(f"legacy icon {name} missing from {icons_json}")
    out[name] = current[name]
  svgs = {p.stem: p for p in icons_dir.glob("*.svg")}
  order = [n for n in GCP_ICONS if n not in out]
  order += sorted(n for n in svgs if n not in out and n not in order)
  for name in order:
    if name not in svgs:
      raise SystemExit(f"registry icon {name} has no {name}.svg in {icons_dir}")
    out[name] = svg_to_entry(svgs[name])
  return json.dumps(out, indent=2)


def main() -> int:
  ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
  ap.add_argument("--check", action="store_true",
                  help="Fail if icons.json differs from a fresh build.")
  args = ap.parse_args()
  text = build()
  if args.check:
    if ICONS_JSON.read_text(encoding="utf-8") != text:
      print("icons.json is stale: run tools/build_icons.py", file=sys.stderr)
      return 1
    print("icons.json up to date")
    return 0
  ICONS_JSON.write_text(text, encoding="utf-8")
  print(f"wrote {ICONS_JSON} ({len(json.loads(text))} icons)")
  return 0


if __name__ == "__main__":
  # Run as a script: make the package next to this tool importable.
  sys.path.insert(0, str(APP_ROOT))
  sys.exit(main())
