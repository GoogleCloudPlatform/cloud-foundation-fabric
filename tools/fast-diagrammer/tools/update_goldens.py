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
"""Regenerates the 2-networking goldens (reviewed golden bumps only).

  python3 tools/update_goldens.py --check   # exit 1 on any drift, write nothing
  python3 tools/update_goldens.py           # rewrite inputs/, expected/, SHA256SUMS

For each of the 12 keys it builds the scene with `stages.networking.build`,
writes the pre-layout snapshot `inputs/<key>.scene.json`, renders
`expected/<key>.drawio{,.svg}` and rewrites `SHA256SUMS`. Datasets resolve
like the tests: vendored fixtures, then `$FD_FABRIC_ROOT`, then the
repository this tool lives in, then `~/git/cloud-foundation-fabric`.
"""

import argparse
import hashlib
import os
import pathlib
import sys

APP_ROOT = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = APP_ROOT / "tests" / "golden" / "2-networking"
DATASETS = ("classic", "hub-and-spokes-ncc", "hub-and-spokes-nva",
            "hub-and-spokes-nva-ncc", "hub-and-spokes-peerings",
            "hub-and-spokes-vpns")
VIEWS = ("topology", "dns")


def _dataset_dir(name: str) -> pathlib.Path:
  roots = [APP_ROOT / "tests" / "fixtures" / "datasets" / "2-networking"]
  if os.environ.get("FD_FABRIC_ROOT"):
    roots.append(pathlib.Path(os.environ["FD_FABRIC_ROOT"]) / "fast" / "stages" /
                 "2-networking" / "datasets")
  roots.append(APP_ROOT.parent.parent / "fast" / "stages" / "2-networking" /
               "datasets")
  roots.append(pathlib.Path.home() / "git" / "cloud-foundation-fabric" / "fast" /
               "stages" / "2-networking" / "datasets")
  for root in roots:
    if (root / name / "vpcs").is_dir():
      return root / name
  raise SystemExit(f"dataset {name} not found (set FD_FABRIC_ROOT)")


def build_all() -> dict:
  """{relative path: bytes} for every golden file, SHA256SUMS included."""
  sys.path.insert(0, str(APP_ROOT))
  # pylint: disable=import-outside-toplevel
  from fast_diagrammer.scene.render import load_icons, render_scene
  from fast_diagrammer.scene.serialize import dumps_scene
  from fast_diagrammer.stages import networking
  icons = load_icons()
  files = {}
  for ds in DATASETS:
    for view in VIEWS:
      key = f"{ds}-{view}"
      files[f"inputs/{key}.scene.json"] = dumps_scene(
          networking.build(_dataset_dir(ds), view, dataset_name=ds)).encode("utf-8")
      res = render_scene(networking.build(_dataset_dir(ds), view, dataset_name=ds), icons)
      files[f"expected/{key}.drawio"] = res.drawio.encode("utf-8")
      files[f"expected/{key}.drawio.svg"] = res.svg.encode("utf-8")
  order = sorted(r for r in files if r.startswith("expected/") and r.endswith(".drawio"))
  order += sorted(r for r in files if r.endswith(".drawio.svg"))
  order += sorted(r for r in files if r.startswith("inputs/"))
  files["SHA256SUMS"] = "".join(
      f"{hashlib.sha256(files[r]).hexdigest()}  {r}\n" for r in order).encode()
  return files


def main() -> int:
  ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
  ap.add_argument("--check", action="store_true", help="Report drift only.")
  args = ap.parse_args()
  files = build_all()
  drift = [r for r, data in files.items()
           if not (GOLDEN / r).is_file() or (GOLDEN / r).read_bytes() != data]
  if args.check:
    for r in drift:
      print(f"drift: {r}", file=sys.stderr)
    print("goldens up to date" if not drift else f"{len(drift)} file(s) drifted")
    return 1 if drift else 0
  for r in drift:
    (GOLDEN / r).parent.mkdir(parents=True, exist_ok=True)
    (GOLDEN / r).write_bytes(files[r])
  print(f"wrote {len(drift)} file(s)")
  return 0


if __name__ == "__main__":
  sys.exit(main())
