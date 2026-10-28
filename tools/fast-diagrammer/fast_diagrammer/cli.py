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
"""Command line: FAST dataset(s) -> `<ds>-<view>.drawio.svg` + `.drawio`.

  fast-diagrammer [INPUT_DIR [OUT_DIR]] [-i DIR | --dataset DIR |
                  --datasets-root DIR | --fast-root STAGES_DIR] [-o OUT_DIR]
                  [-t|-s auto|org-setup|vpc-sc|net|0-org-setup|1-vpcsc|2-networking]
                  [--views v1,v2] [--org-dataset DIR] [--verbose-badges]
                  [--legend | --no-legend] [--rasterizer "CMD {svg} {png}"]
                  [--rpz-bind-lines] [--strict]

An input folder (positional, `-i/--input` or `--dataset`) may be a single
dataset (`fast/stages/0-org-setup/datasets/classic`), a datasets folder
(`.../datasets`) or a stage folder (`fast/stages/0-org-setup`); the last two
render every dataset inside. `--fast-root` renders every `*/datasets/*` of
the supported stages into `<out>/<stage>/` so equally named datasets never
collide. Input directories are only ever read.
"""

import argparse
import os
import pathlib
import shlex
import subprocess
import sys
from typing import Any, Dict, List, Optional, Sequence, Tuple

from .datasets.base import (STAGES, Dataset, PathLike, StageDetectionError,
                            detect_stage, discover_datasets, discover_fast_root)
from .scene.render import OverlapError, load_icons, render
from .stages import accepted_options, get_builder


STAGE_ALIASES = {
    "auto": "auto",
    "0-org-setup": "0-org-setup",
    "org-setup": "0-org-setup",
    "org_setup": "0-org-setup",
    "org": "0-org-setup",
    "1-vpcsc": "1-vpcsc",
    "vpc-sc": "1-vpcsc",
    "vpc_sc": "1-vpcsc",
    "vpcsc": "1-vpcsc",
    "2-networking": "2-networking",
    "networking": "2-networking",
    "net": "2-networking",
}


def stage_type(value: str) -> str:
  """argparse type: maps a stage alias to its canonical FAST stage name."""
  key = value.strip().lower()
  if key not in STAGE_ALIASES:
    raise argparse.ArgumentTypeError(
        f"unknown stage {value!r} (choose from {', '.join(STAGE_ALIASES)})")
  return STAGE_ALIASES[key]


def _parser() -> argparse.ArgumentParser:
  p = argparse.ArgumentParser(
      prog="fast-diagrammer",
      description="Render Cloud Foundation Fabric FAST stage datasets "
      "(0-org-setup, 1-vpcsc, 2-networking) as .drawio.svg + .drawio.")
  p.add_argument("input_dir", nargs="?",
                 help="Dataset, datasets folder or stage folder to render.")
  p.add_argument("out_dir_pos", nargs="?", metavar="out_dir",
                 help="Output directory (alternative to -o/--out-dir).")
  p.add_argument("-i", "--input", help="Same as the positional input_dir.")
  p.add_argument("--dataset", help="Dataset (or datasets/stage folder).")
  p.add_argument("--datasets-root",
                 help="Directory whose sub-directories are datasets of one stage.")
  p.add_argument("--fast-root",
                 help="FAST stages directory (renders every */datasets/*).")
  p.add_argument("-o", "--out-dir", help="Output directory.")
  p.add_argument("-s", "--stage", "-t", "--type", dest="stage", default="auto",
                 type=stage_type, metavar="STAGE",
                 help="Stage instead of auto-detection: org-setup, vpc-sc, net "
                 "(or 0-org-setup, 1-vpcsc, 2-networking).")
  p.add_argument("--views", default="",
                 help="Comma-separated views (default: all views of the stage).")
  p.add_argument("--org-dataset",
                 help="Sibling 0-org-setup dataset used to enrich 1-vpcsc sets.")
  p.add_argument("--verbose-badges", action="store_true",
                 help="Lift the default badge budget.")
  leg = p.add_mutually_exclusive_group()
  leg.add_argument("--legend", dest="legend", action="store_true", default=None,
                   help="Force the legend on.")
  leg.add_argument("--no-legend", dest="legend", action="store_false",
                   help="Force the legend off.")
  p.add_argument("--rasterizer", default=os.environ.get("FD_RASTERIZER", ""),
                 help='Optional PNG command template, e.g. "CMD {svg} {png}" '
                 "(env FD_RASTERIZER). PNG output is never required.")
  p.add_argument("--rpz-bind-lines", action="store_true",
                 help="2-networking dns: draw explicit RPZ bind edges.")
  p.add_argument("--strict", action="store_true",
                 help="Exit non-zero on unknown icons (non-networking stages) "
                 "or unresolved symbolic sets.")
  return p


def _rasterize(template: str, svg: pathlib.Path) -> Optional[str]:
  png = svg.with_name(svg.name[:-len(".drawio.svg")] + ".png")
  cmd = [part.format(svg=str(svg), png=str(png)) for part in shlex.split(template)]
  try:
    subprocess.run(cmd, check=True, capture_output=True, timeout=120)
  except (OSError, subprocess.SubprocessError) as exc:
    return f"rasterizer failed for {svg.name}: {exc}"
  return None


def _select_views(module, requested: List[str]) -> List[str]:
  views = list(getattr(module, "VIEWS", ()))
  if not requested:
    return views
  return [v for v in requested if v in views]


def _is_dataset(path: pathlib.Path) -> bool:
  try:
    detect_stage(path)
  except StageDetectionError:
    return False
  return True


def resolve_input(path: PathLike) -> Tuple[bool, List[pathlib.Path]]:
  """Smart input folder: `(is_root, dataset_dirs)`.

  A stage folder (has `datasets/`) or a folder whose sub-directories are
  datasets renders every dataset inside; anything else is one dataset.
  """
  p = pathlib.Path(path)
  if (p / "datasets").is_dir():
    return True, discover_datasets(p / "datasets")
  if not _is_dataset(p):
    subs = discover_datasets(p)
    if any(_is_dataset(d) for d in subs):
      return True, subs
  return False, [p]


def _collect(args, parser) -> Tuple[str, List[pathlib.Path]]:
  """`(mode, dataset_dirs)`; mode is "single", "root" or "fast"."""
  given = [v for v in (args.input_dir, args.input, args.dataset,
                       args.datasets_root, args.fast_root) if v]
  if len(given) != 1:
    parser.error("give exactly one input: input_dir, -i/--input, --dataset, "
                 "--datasets-root or --fast-root")
  if args.fast_root:
    return "fast", list(discover_fast_root(args.fast_root))
  if args.datasets_root:
    return "root", discover_datasets(args.datasets_root)
  is_root, dirs = resolve_input(given[0])
  return ("root" if is_root else "single"), dirs


def run(argv: Optional[Sequence[str]] = None) -> int:
  parser = _parser()
  args = parser.parse_args(argv)
  flagged_input = args.input or args.dataset or args.datasets_root or args.fast_root
  if flagged_input and args.input_dir and not args.out_dir_pos:
    # `-i IN OUT`: with the input given by flag, a lone positional is the output.
    args.out_dir_pos, args.input_dir = args.input_dir, None
  out_dir_arg = args.out_dir or args.out_dir_pos
  if not out_dir_arg:
    parser.error("an output directory is required (-o/--out-dir or second positional)")
  if args.out_dir and args.out_dir_pos:
    parser.error("give the output directory once (-o/--out-dir or positional)")
  mode, collected = _collect(args, parser)
  out_root = pathlib.Path(out_dir_arg)
  out_root.mkdir(parents=True, exist_ok=True)
  requested = [v.strip() for v in args.views.split(",") if v.strip()]
  icons = load_icons()

  options: Dict[str, Any] = {
      "rpz_bind_lines": args.rpz_bind_lines,
      "verbose_badges": args.verbose_badges,
      "strict": args.strict,
  }
  if args.legend is not None:
    options["legend"] = args.legend
  if args.org_dataset:
    options["org_dataset"] = pathlib.Path(args.org_dataset)

  failures: List[str] = []
  rendered = 0
  if mode == "fast":
    dirs = collected
  else:
    dirs = [(None, d) for d in collected]
  if not dirs:
    print("no datasets found", file=sys.stderr)
    return 2
  for stage_hint, ds_dir in dirs:
    if mode == "fast":
      if stage_hint not in STAGES or (args.stage != "auto" and stage_hint != args.stage):
        print(f"[skip] {stage_hint}/{ds_dir.name}: stage not rendered",
              file=sys.stderr)
        continue
      ds = Dataset.from_path(ds_dir, stage_hint)
    else:
      try:
        ds = Dataset.from_path(ds_dir, args.stage)
      except StageDetectionError as exc:
        if mode == "root":
          print(f"[skip] {exc}", file=sys.stderr)
          continue
        failures.append(str(exc))
        continue
    module = get_builder(ds.stage)
    views = _select_views(module, requested)
    if not views:
      print(f"[skip] {ds.stage}/{ds.name}: no matching view in {requested}",
            file=sys.stderr)
      continue
    out_dir = out_root / ds.stage if mode == "fast" else out_root
    out_dir.mkdir(parents=True, exist_ok=True)
    for view in views:
      key = f"{ds.name}-{view}"
      try:
        kwargs = accepted_options(module.build, options)
        scene = module.build(ds.root, view, dataset_name=ds.name, **kwargs)
        if not scene.stage:
          scene.stage = ds.stage
        result = render(scene, icons, out_dir / f"{key}.drawio.svg",
                        out_dir / f"{key}.drawio")
      except OverlapError as exc:
        failures.append(f"{ds.stage}/{key}: {exc}")
        continue
      except Exception as exc:  # pylint: disable=broad-except
        failures.append(f"{ds.stage}/{key}: {type(exc).__name__}: {exc}")
        continue
      rendered += 1
      print(f"[OK] {out_dir / (key + '.drawio.svg')}")
      if result.unknown_icons:
        msg = f"{ds.stage}/{key}: unknown icons {result.unknown_icons} (CloudGeneric fallback)"
        if args.strict and ds.stage != "2-networking":
          failures.append(msg)
        else:
          print(f"[warn] {msg}", file=sys.stderr)
      if args.rasterizer:
        err = _rasterize(args.rasterizer, out_dir / f"{key}.drawio.svg")
        if err:
          print(f"[warn] {err}", file=sys.stderr)

  for f in failures:
    print(f"[FAIL] {f}", file=sys.stderr)
  print(f"{rendered} diagram(s) rendered, {len(failures)} failure(s)")
  return 1 if failures else 0


def main() -> None:
  sys.exit(run())
