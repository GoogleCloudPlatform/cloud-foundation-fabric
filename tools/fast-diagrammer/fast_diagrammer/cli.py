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
                  [--views v1,v2] [--org-dataset DIR] [--cicd-workflows FILE]
                  [--verbose-badges]
                  [--legend | --no-legend] [--rasterizer "CMD {svg} {png}"]
                  [--rpz-bind-lines] [--strict]

An input folder (positional, `-i/--input` or `--dataset`) may be a single
dataset (`fast/stages/0-org-setup/datasets/classic`), a datasets folder
(`.../datasets`) or a stage folder (`fast/stages/0-org-setup`); the last two
render every dataset inside. `--fast-root` renders every `*/datasets/*` of
the supported stages into `<out>/<stage>/` so equally named datasets never
collide. Folder runs skip symlinked datasets (an alias such as `classic`
would render the same diagrams twice) and say so; a symlink given as a
single dataset renders under the name it was given.

Input directories are only ever read: an output directory equal to or inside
an input dataset is refused.

Exit status: 0 when every requested diagram rendered; 1 when anything failed
(stage detection, build, overlap gate, `--strict`, unwritable output); 2 on a
usage error or when nothing was rendered.
"""

import argparse
import os
import pathlib
import shlex
import subprocess
import sys
import warnings
from typing import Any, Dict, List, Optional, Sequence, Tuple

from .datasets.base import (STAGES, Dataset, PathLike, StageDetectionError,
                            detect_stage, discover_datasets, discover_fast_root,
                            symlinked_datasets)
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
      "(0-org-setup, 1-vpcsc, 2-networking) as .drawio.svg + .drawio.",
      epilog="Exit status: 0 all rendered, 1 any failure, 2 usage error or "
      "nothing rendered.")
  p.add_argument("input_dir", nargs="?",
                 help="Dataset, datasets folder or stage folder to render.")
  p.add_argument("out_dir_pos", nargs="?", metavar="out_dir",
                 help="Output directory (alternative to -o/--out-dir).")
  p.add_argument("-i", "--input", help="Same as the positional input_dir.")
  p.add_argument("--dataset", help="Dataset (or datasets/stage folder).")
  p.add_argument(
      "--datasets-root",
      help="Directory whose sub-directories are datasets of one stage.")
  p.add_argument("--fast-root",
                 help="FAST stages directory (renders every */datasets/*).")
  p.add_argument("-o", "--out-dir", help="Output directory.")
  p.add_argument(
      "-s", "--stage", "-t", "--type", dest="stage", default="auto",
      type=stage_type, metavar="STAGE",
      help="Stage instead of auto-detection: org-setup, vpc-sc, net "
      "(or 0-org-setup, 1-vpcsc, 2-networking); warns when the "
      "dataset looks like another stage.")
  p.add_argument(
      "--views", default="",
      help="Comma-separated views (default: all views of the "
      "stage); unknown names are an error.")
  p.add_argument(
      "--org-dataset",
      help="Sibling 0-org-setup dataset used to enrich 1-vpcsc sets.")
  p.add_argument(
      "--cicd-workflows", metavar="FILE",
      help="0-org-setup: CI/CD workflows file, relative to the dataset "
      "(stage paths.cicd_workflows, unset by default), e.g. cicd.yaml.")
  p.add_argument("--verbose-badges", action="store_true",
                 help="Lift the default badge budget.")
  leg = p.add_mutually_exclusive_group()
  leg.add_argument("--legend", dest="legend", action="store_true", default=None,
                   help="Force the legend on.")
  leg.add_argument("--no-legend", dest="legend", action="store_false",
                   help="Force the legend off.")
  p.add_argument(
      "--rasterizer", default=os.environ.get("FD_RASTERIZER", ""),
      help='Optional PNG command template, e.g. "CMD {svg} {png}" '
      "(env FD_RASTERIZER). Failures are warnings; PNG output is "
      "never required.")
  p.add_argument("--rpz-bind-lines", action="store_true",
                 help="2-networking dns: draw explicit RPZ bind edges.")
  p.add_argument(
      "--strict", action="store_true",
      help="Exit non-zero on unknown icons (non-networking stages) "
      "or unresolved symbolic sets.")
  return p


def _warn(msg: str) -> None:
  print(f"[warn] {msg}", file=sys.stderr)


def _skip(msg: str) -> None:
  print(f"[skip] {msg}", file=sys.stderr)


def _error(msg: str) -> None:
  print(f"[error] {msg}", file=sys.stderr)


def _template_error(template: str) -> Optional[str]:
  """Why a `--rasterizer` template is unusable, or None when it is fine."""
  try:
    parts = shlex.split(template)
    for part in parts:
      part.format(svg="in.drawio.svg", png="out.png")
  except (ValueError, KeyError, IndexError, AttributeError) as exc:
    return f"{type(exc).__name__}: {exc}"
  if not parts:
    return "empty command"
  return None


def _rasterize(template: str, svg: pathlib.Path) -> Optional[str]:
  png = svg.with_name(svg.name[:-len(".drawio.svg")] + ".png")
  try:
    cmd = [
        part.format(svg=str(svg), png=str(png))
        for part in shlex.split(template)
    ]
    subprocess.run(cmd, check=True, capture_output=True, timeout=120)
  except (ValueError, KeyError, IndexError, AttributeError, OSError,
          subprocess.SubprocessError) as exc:
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


def _skip_symlinks(folder: pathlib.Path, prefix: str = "") -> None:
  for link, target in symlinked_datasets(folder):
    shown = target.name if target.parent == link.parent.resolve() else target
    _skip(f"{prefix}{link.name} -> {shown} (symlink)")


def resolve_input(
    path: PathLike) -> Tuple[Optional[pathlib.Path], List[pathlib.Path]]:
  """Smart input folder: `(datasets_folder, dataset_dirs)`.

  A stage folder (has `datasets/`) or a folder whose sub-directories are
  datasets renders every dataset inside and returns that folder; anything
  else is one dataset and returns `(None, [path])`.
  """
  p = pathlib.Path(path)
  if (p / "datasets").is_dir():
    return p / "datasets", discover_datasets(p / "datasets")
  if not _is_dataset(p):
    subs = discover_datasets(p)
    if any(_is_dataset(d) for d in subs):
      return p, subs
  return None, [p]


def _collect(args,
             parser) -> Tuple[str, List[Tuple[Optional[str], pathlib.Path]]]:
  """`(mode, [(stage_hint, dataset_dir)])`; mode is "single", "root" or "fast".

  Prints a `[skip]` line for every symlinked dataset of a folder run.
  """
  given = [
      v for v in (args.input_dir, args.input, args.dataset, args.datasets_root,
                  args.fast_root) if v
  ]
  if len(given) != 1:
    parser.error("give exactly one input: input_dir, -i/--input, --dataset, "
                 "--datasets-root or --fast-root")
  if not pathlib.Path(given[0]).is_dir():
    parser.error(f"input {given[0]} is not an existing directory")
  if args.fast_root:
    stages_dir = pathlib.Path(args.fast_root)
    if stages_dir.is_dir():
      for stage_dir in sorted(p for p in stages_dir.iterdir() if p.is_dir()):
        if stage_dir.name in STAGES and args.stage in ("auto", stage_dir.name):
          _skip_symlinks(stage_dir / "datasets", f"{stage_dir.name}/")
    return "fast", list(discover_fast_root(stages_dir))
  if args.datasets_root:
    folder = pathlib.Path(args.datasets_root)
    dirs = discover_datasets(folder)
  else:
    folder, dirs = resolve_input(given[0])
  if folder is None:
    return "single", [(None, d) for d in dirs]
  _skip_symlinks(folder)
  return "root", [(None, d) for d in dirs]


def _plan(mode: str, stage_hint: Optional[str], ds_dir: pathlib.Path,
          stage: str, failures: List[str]) -> Optional[Dataset]:
  """The dataset to render, or None after printing/recording why not."""
  if mode == "fast":
    # The stage directory name is authoritative: unsupported stages such as
    # 2-project-factory are skipped whatever their datasets look like.
    if stage_hint not in STAGES or stage not in ("auto", stage_hint):
      _skip(f"{stage_hint}/{ds_dir.name}: stage not rendered")
      return None
    return Dataset.from_path(ds_dir, stage_hint)
  try:
    detected: Optional[str] = detect_stage(ds_dir)
    why: Optional[StageDetectionError] = None
  except StageDetectionError as exc:
    detected, why = None, exc
  if detected is None:
    if mode == "root":
      _skip(str(why))
      return None
    if stage == "auto":
      failures.append(str(why))
      return None
    _warn(f"{ds_dir}: no FAST stage fingerprint found, rendering as {stage} "
          "because of -t/--type")
  elif stage == "auto":
    stage = detected
  elif detected != stage:
    _warn(f"{ds_dir}: looks like a {detected} dataset, rendering as {stage} "
          "because of -t/--type")
  return Dataset.from_path(ds_dir, stage)


def _check_views(parser, requested: List[str], jobs: List[Dataset]) -> None:
  """argparse error for `--views` names no stage being rendered knows."""
  if not requested:
    return
  stages = sorted({ds.stage for ds in jobs}) or list(STAGES)
  valid = {s: tuple(getattr(get_builder(s), "VIEWS", ())) for s in stages}
  known = {v for views in valid.values() for v in views}
  bad = [v for v in requested if v not in known]
  if bad:
    choices = "; ".join(f"{s}: {', '.join(v)}" for s, v in valid.items())
    parser.error(f"unknown view(s) {', '.join(bad)} (valid views: {choices})")


def _check_out_dir(parser, out_root: pathlib.Path,
                   inputs: List[pathlib.Path]) -> None:
  """argparse error when the output directory is (inside) an input dataset."""
  out_abs = out_root.resolve()
  for ds_dir in inputs:
    src = ds_dir.resolve()
    if out_abs == src or out_abs.is_relative_to(src):
      parser.error(f"output directory {out_root} is inside input dataset "
                   f"{ds_dir}: inputs are never written")


def _build(module, ds: Dataset, view: str, options: Dict[str, Any], seen: set):
  """Builds one view; loader/builder warnings become `[warn]` lines, once
  per dataset, even when the build fails."""
  with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")
    try:
      kwargs = accepted_options(module.build, options)
      scene = module.build(ds.root, view, dataset_name=ds.name, **kwargs)
    finally:
      for w in caught:
        msg = str(w.message)
        if msg not in seen:
          seen.add(msg)
          _warn(f"{ds.stage}/{ds.name}: {msg}")
  if not scene.stage:
    scene.stage = ds.stage
  return scene


class _OutputError(Exception):
  """The output directory or an output file cannot be written."""


def run(argv: Optional[Sequence[str]] = None) -> int:
  parser = _parser()
  args = parser.parse_args(argv)
  flagged_input = (args.input or args.dataset or args.datasets_root or
                   args.fast_root)
  if flagged_input and args.input_dir and not args.out_dir_pos:
    # `-i IN OUT`: with a flagged input, a lone positional is the output.
    args.out_dir_pos, args.input_dir = args.input_dir, None
  out_dir_arg = args.out_dir or args.out_dir_pos
  if not out_dir_arg:
    parser.error(
        "an output directory is required (-o/--out-dir or second positional)")
  if args.out_dir and args.out_dir_pos:
    parser.error("give the output directory once (-o/--out-dir or positional)")
  if args.org_dataset and not pathlib.Path(args.org_dataset).is_dir():
    parser.error(f"--org-dataset {args.org_dataset} is not an existing "
                 "directory")
  mode, pairs = _collect(args, parser)
  if not pairs:
    _error("no datasets found")
    return 2
  out_root = pathlib.Path(out_dir_arg)
  _check_out_dir(parser, out_root, [d for _, d in pairs])
  requested = [v.strip() for v in args.views.split(",") if v.strip()]

  failures: List[str] = []
  jobs = []
  for stage_hint, ds_dir in pairs:
    ds = _plan(mode, stage_hint, ds_dir, args.stage, failures)
    if ds is not None:
      jobs.append(ds)
  _check_views(parser, requested, jobs)

  rasterizer = args.rasterizer.strip()
  if rasterizer:
    why = _template_error(rasterizer)
    if why:
      _warn(f"ignoring --rasterizer/FD_RASTERIZER template {rasterizer!r} "
            f"({why}); no PNG will be written")
      rasterizer = ""

  options: Dict[str, Any] = {
      "rpz_bind_lines": args.rpz_bind_lines,
      "verbose_badges": args.verbose_badges,
      "strict": args.strict,
  }
  if args.legend is not None:
    options["legend"] = args.legend
  if args.org_dataset:
    options["org_dataset"] = pathlib.Path(args.org_dataset)
  if args.cicd_workflows:
    options["cicd_workflows"] = args.cicd_workflows
    if not any(ds.stage == "0-org-setup" for ds in jobs):
      _warn("--cicd-workflows only applies to 0-org-setup datasets")

  icons = load_icons()
  rendered = 0
  try:
    if jobs:
      _make_dir(out_root)
    for ds in jobs:
      module = get_builder(ds.stage)
      views = _select_views(module, requested)
      if not views:
        _skip(f"{ds.stage}/{ds.name}: no matching view in {requested}")
        continue
      out_dir = out_root / ds.stage if mode == "fast" else out_root
      _make_dir(out_dir)
      seen: set = set()
      for view in views:
        key = f"{ds.name}-{view}"
        svg_path = out_dir / f"{key}.drawio.svg"
        try:
          scene = _build(module, ds, view, options, seen)
          result = render(scene, icons, svg_path, out_dir / f"{key}.drawio")
        except OverlapError as exc:
          failures.append(f"{ds.stage}/{key}: {exc}")
          continue
        except OSError as exc:
          if exc.filename and pathlib.Path(exc.filename).parent == out_dir:
            raise _OutputError(f"cannot write {exc.filename}: "
                               f"{exc.strerror or exc}") from exc
          failures.append(f"{ds.stage}/{key}: {type(exc).__name__}: {exc}")
          continue
        except Exception as exc:  # pylint: disable=broad-except
          failures.append(f"{ds.stage}/{key}: {type(exc).__name__}: {exc}")
          continue
        rendered += 1
        print(f"[OK] {svg_path}")
        if result.unknown_icons:
          msg = (f"{ds.stage}/{key}: unknown icons {result.unknown_icons} "
                 "(CloudGeneric fallback)")
          if args.strict and ds.stage != "2-networking":
            failures.append(msg)
          else:
            _warn(msg)
        if rasterizer:
          err = _rasterize(rasterizer, svg_path)
          if err:
            _warn(err)
  except _OutputError as exc:
    _error(str(exc))
    return 1

  for f in failures:
    print(f"[FAIL] {f}", file=sys.stderr)
  print(f"{rendered} diagram(s) rendered, {len(failures)} failure(s)")
  if failures:
    return 1
  if not rendered:
    _error("no diagrams rendered")
    return 2
  return 0


def _make_dir(path: pathlib.Path) -> None:
  if path.exists() and not path.is_dir():
    raise _OutputError(f"output path {path} exists and is not a directory")
  try:
    path.mkdir(parents=True, exist_ok=True)
  except OSError as exc:
    raise _OutputError(f"cannot create output directory {path}: "
                       f"{exc.strerror or exc}") from exc


def main() -> None:
  sys.exit(run())
