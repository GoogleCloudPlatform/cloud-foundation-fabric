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

  python3 tools/fast-diagrammer/tools/update_goldens.py --check   # report drift
  python3 tools/fast-diagrammer/tools/update_goldens.py           # rewrite

The goldens are the regression contract of this tool: any change to the
2-networking builder, the layout engine, the router or the emitters that
alters a byte shows up as a test failure. Regenerate them only in a reviewed
bump, saying in the commit message why the pictures changed.

For each of the 12 keys it builds the scene with `stages.networking.build`,
writes the pre-layout snapshot `inputs/<key>.scene.json`, renders
`expected/<key>.drawio{,.svg}` and rewrites `SHA256SUMS`. `--check` writes
nothing and exits 1 on any drift. Like the tests, a `.drawio.svg` whose
inflated `content=` matches the golden is not drift (raw deflate bytes differ
between zlib builds), and the golden file is kept as it is.

Datasets resolve exactly like the tests (`tests/conftest.py`, so pytest must
be installed, see `tests/requirements.txt`): the repository's `fast/stages`
first, then `$FD_FABRIC_ROOT/fast/stages`.
"""

import argparse
import hashlib
import pathlib
import sys

APP_ROOT = pathlib.Path(__file__).resolve().parent.parent
TESTS_DIR = APP_ROOT / "tests"
sys.path.insert(0, str(APP_ROOT))
sys.path.insert(0, str(TESTS_DIR))

# pylint: disable=wrong-import-position
from conftest import (GOLDEN_DATASETS, GOLDEN_DIR, GOLDEN_VIEWS, canonical_svg,
                      dataset_dir, missing_dataset_reason)


def _dataset_dir(name: str) -> pathlib.Path:
  d = dataset_dir("2-networking", name)
  if d is None:
    raise SystemExit(missing_dataset_reason("2-networking", name))
  return d


def build_all() -> dict:
  """{relative path: bytes} for every golden file, SHA256SUMS included."""
  # pylint: disable=import-outside-toplevel
  from fast_diagrammer.scene.render import load_icons, render_scene
  from fast_diagrammer.scene.serialize import dumps_scene
  from fast_diagrammer.stages import networking
  icons = load_icons()
  files = {}
  for ds in GOLDEN_DATASETS:
    for view in GOLDEN_VIEWS:
      key = f"{ds}-{view}"
      files[f"inputs/{key}.scene.json"] = dumps_scene(
          networking.build(_dataset_dir(ds), view,
                           dataset_name=ds)).encode("utf-8")
      res = render_scene(
          networking.build(_dataset_dir(ds), view, dataset_name=ds), icons)
      files[f"expected/{key}.drawio"] = res.drawio.encode("utf-8")
      svg = res.svg.encode("utf-8")
      golden_svg = GOLDEN_DIR / f"expected/{key}.drawio.svg"
      if golden_svg.is_file() and canonical_svg(
          golden_svg.read_bytes()) == canonical_svg(svg):
        svg = golden_svg.read_bytes()  # same diagram, other zlib build
      files[f"expected/{key}.drawio.svg"] = svg
  order = sorted(
      r for r in files if r.startswith("expected/") and r.endswith(".drawio"))
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
  drift = [
      r for r, data in files.items()
      if not (GOLDEN_DIR / r).is_file() or (GOLDEN_DIR / r).read_bytes() != data
  ]
  if args.check:
    for r in drift:
      print(f"drift: {r}", file=sys.stderr)
    print(
        "goldens up to date" if not drift else f"{len(drift)} file(s) drifted")
    return 1 if drift else 0
  for r in drift:
    (GOLDEN_DIR / r).parent.mkdir(parents=True, exist_ok=True)
    (GOLDEN_DIR / r).write_bytes(files[r])
  print(f"wrote {len(drift)} file(s)")
  return 0


if __name__ == "__main__":
  sys.exit(main())
