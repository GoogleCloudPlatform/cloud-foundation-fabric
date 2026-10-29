# fast-diagrammer

Deterministic diagram generator for Cloud Foundation Fabric FAST stage
datasets. It reads a dataset directory, builds a stage-agnostic scene graph in
plain Python, lays it out with a small flexbox engine, routes every edge
orthogonally with zero overlaps, and writes two files per view:

- `<dataset>-<view>.drawio.svg`: an SVG that also embeds the draw.io model
  (open it in a browser, or edit it in diagrams.net);
- `<dataset>-<view>.drawio`: the standalone draw.io model.

The `.drawio` is plain, diffable mxfile XML in which every card and zone icon
is an embedded image cell, so it opens fully editable in diagrams.net; the
`.drawio.svg` carries the same diagram in its `content=` attribute in
draw.io's native compressed form (raw deflate + base64), so it is editable in
diagrams.net too. Review diffs on the `.drawio`.

The package is `fast_diagrammer/` (Python 3.10+, stdlib plus `PyYAML`).

| Stage | Views | What the diagram answers |
|---|---|---|
| `0-org-setup` | `hierarchy` | Where folders and projects live (exact project-factory parent rules), what each core project is for (≤4 badges), which org-level controls exist, billing account, log sink / billing export / Shared VPC edges. |
| `1-vpcsc` | `perimeters` | What is inside each perimeter, enforced or dry-run, who can get in (ingress), who can get out (egress), under which access level. Stage-generated sets are dashed "set" cards with provenance. |
| `2-networking` | `topology`, `dns` | Projects → VPCs → routers, VPN/VLAN, NCC, NVAs, peerings (topology); zones, resolvers, bind/peer/forward chains (dns). Byte-identical to the goldens (`tests/golden/2-networking/`), the regression contract of this tool. |

```mermaid
flowchart LR
  DS["dataset dir (YAML)"] --> DET["datasets/base.py: detect_stage"]
  DET --> LOAD["datasets/{org_setup,vpcsc,networking}.py: loaders"]
  LOAD --> BUILD["stages/*.py: build(dataset, view) -> SceneGraph"]
  BUILD --> LAY["scene/layout.py: measure, place, closest-side anchors"]
  LAY --> ROUTE["scene/router.py: orthogonal routes + overlap gate"]
  ROUTE --> EMIT["scene/emit_drawio.py + emit_svg.py"]
  EMIT --> OUT[".drawio.svg + .drawio"]
```

## Quick start

Run from the root of the repository.

```bash
pip install PyYAML       # the only runtime dependency (already in tests/requirements.txt)

# One dataset; the stage type is optional (auto-detected when omitted)
python3 tools/fast-diagrammer fast/stages/0-org-setup/datasets/classic \
  --type org-setup --out-dir /tmp/fd

# Executable script, short flags, VPC-SC enriched from the sibling org-setup dataset
./tools/fast-diagrammer/fast_diagrammer.py fast/stages/1-vpcsc/datasets/hardened \
  -t vpc-sc -o /tmp/fd --org-dataset fast/stages/0-org-setup/datasets/hardened

# A stage folder (or its datasets/ folder) renders every dataset inside it
python3 tools/fast-diagrammer fast/stages/2-networking -t net /tmp/fd

# Every supported stage of a FAST checkout, written to /tmp/fd/<stage>/
PYTHONPATH=tools/fast-diagrammer python3 -m fast_diagrammer \
  --fast-root fast/stages --out-dir /tmp/fd

# Tests (pytest and PyYAML come from tests/requirements.txt)
python3 -m pytest tools/fast-diagrammer/tests
```

The tests are run in CI by the `schemas` job of `.github/workflows/tests.yml`.
They read the reference datasets from this repository's `fast/stages/`; a
copy of the tool outside the repository finds them through
`FD_FABRIC_ROOT`, and without either the dataset-dependent tests are skipped
with the searched paths as the reason.

## CLI

| Argument / env | Default | Description |
|---|---|---|
| `INPUT_DIR` (positional), `-i/--input DIR`, `--dataset DIR` | one input required | A dataset (`.../datasets/classic`), a datasets folder (`.../datasets`) or a stage folder (`fast/stages/0-org-setup`). Folders render every dataset inside; sub-directories that are not datasets are skipped, and so are symlinked datasets (`[skip] classic -> hub-and-spokes-peerings (symlink)`), which would only render an alias twice. A symlink given as a single dataset renders under the name it was given (`classic-*`). |
| `--datasets-root DIR` | | Directory whose sub-directories are datasets. |
| `--fast-root DIR` | | FAST `stages/` directory: every `*/datasets/*` of the supported stages (the stage comes from the stage directory name), written to `<out>/<stage>/`. |
| `OUT_DIR` (second positional), `-o/--out-dir DIR` | required | Output directory, created if missing. Inputs are never written: an output directory equal to or inside an input dataset is refused. |
| `-t/--type`, `-s/--stage` | `auto` | `org-setup` / `org` / `0-org-setup`, `vpc-sc` / `vpcsc` / `1-vpcsc`, `net` / `networking` / `2-networking`; `auto` uses fingerprint detection. An explicit stage still runs the detection and warns when the dataset looks like another stage, or like none (a single dataset only: folder runs skip sub-directories that are not datasets). |
| `--views a,b` | all views of the stage | Subset of views to render; a name that no rendered stage has is a usage error listing the valid views. |
| `--org-dataset DIR` | unset | 1-vpcsc: resolve `logging_project`, `org_setup_projects` and sink identities from a 0-org-setup dataset. |
| `--cicd-workflows FILE` | unset | 0-org-setup: read CI/CD workflows from `FILE`, relative to the dataset (the stage's `factories_config.paths.cicd_workflows`, unset by default), e.g. `cicd.yaml`; without it no CI/CD card is drawn, as the stage does not read the file either. |
| `--verbose-badges` | off | Lift the default badge budget (4 per card, 6 per zone header). |
| `--legend` / `--no-legend` | on | Force the bottom-left legend on or off, on every stage. |
| `--rpz-bind-lines` | off | 2-networking dns: draw explicit dashed `Bind (RPZ)` edges. |
| `--strict` | off | Non-zero exit on unknown icons (stages 0/1) or unresolved `$ns:key` sets. |
| `--rasterizer "CMD {svg} {png}"` / `FD_RASTERIZER` | unset | Optional PNG step, run once per diagram with `{svg}` and `{png}` substituted. A failing command or a malformed template (`{oops}`, a lone `{`) is a warning. PNG is never required. |
| `FD_FABRIC_ROOT` | unset | Tests only: Fabric checkout to read the reference datasets from when the tool does not sit inside one (the repository's own `fast/stages` wins). |

Exit status: `0` when every requested diagram rendered; `1` when anything
failed (stage detection of a single dataset, a build error, the overlap gate,
`--strict`, an unwritable output directory); `2` on a usage error (including
an input or `--org-dataset` that is not an existing directory) or when nothing
was rendered (for example a stage folder with no supported dataset).

Stage detection (first match wins): `perimeters/` or `restricted-services.yaml`
→ `1-vpcsc`; `organization/` → `0-org-setup` (`starter-gcd` also has `vpcs/`,
rendered as embedded VPCs); `vpcs/` together with `ncc-hubs/`, `nvas/` or a
top-level `vpcs:` key in `defaults.yaml` → `2-networking`. `folders/` alone is
not a fingerprint, so 2-project-factory and 2-security datasets are refused
rather than misread.

## Visual vocabulary

Colour is never the only cue: every semantic also has a dash, head or shape.

| Element | Meaning |
|---|---|
| solid line, filled head | traffic / ingress / Shared VPC service |
| dashed `6 4`, open head | egress / outbound |
| dotted `2 3` | policy binding (access level, billing export) |
| dash-dot `8 3 2 3` | log sink routing |
| dashed card border | symbolic or discovered set, not a concrete resource |
| pill badges | key facts (log buckets, CMEK, Shared VPC host, ENFORCED / DRY-RUN …) |

## Layout of the package

- `fast_diagrammer/scene/`: rendering core. `model.py` (zones, cards, edges,
  badges, legend, `PALETTE`, `STYLE_PRESETS`, `GCP_ICONS`, `make_zone` /
  `make_card` / `make_edge`), `layout.py`, `router.py`, `emit_drawio.py`,
  `emit_svg.py`, `render.py` (`render`, `render_scene`, `load_icons`),
  `serialize.py` (lossless pre-layout JSON snapshots).
- `fast_diagrammer/datasets/`: YAML → plain stage models; `base.py` holds
  `detect_stage` and `Dataset`.
- `fast_diagrammer/stages/`: one builder per stage, contract
  `VIEWS` + `build(dataset_dir, view, dataset_name=None, **options)`.
- `fast_diagrammer/{tokens,yamlio}.py`: `$type:key` helpers; YAML loader with
  YAML 1.2 scalar semantics: `NO`, `on`, `yes` stay strings and dates stay
  strings. Terraform's `yamldecode` reads plain `yes/no/on/off/y/n` as
  booleans, so the tool warns on such unquoted values; quote them in the
  dataset. Loader and builder warnings are printed as `[warn]` lines and never
  change the exit status.
- `fast_diagrammer/icons/`: the SVG glyphs and `icons.json`, built by
  `tools/build_icons.py` (`--check` in the gate). The 13 legacy networking
  glyphs and the 24 newer glyphs in `fast_diagrammer/icons/` are the author's
  own drawings, made with Google-owned tooling and licensed under Apache 2.0
  like the rest of this repository. They are not the official Google Cloud
  icon set.
- `__main__.py`, `fast_diagrammer.py`: entry points for `python3 <dir>` and
  `./fast_diagrammer.py`.
- `tests/`: `test_layout_gates.py` (core gates and the CLI),
  `test_parity_networking.py` (2-networking goldens), one `test_<area>.py`
  per component (emitters, router, stage builders), and
  `golden/2-networking/` (byte-level regression goldens and pre-layout scene
  snapshots, see its `README.md`; regenerate only in a reviewed bump with
  `tools/fast-diagrammer/tools/update_goldens.py`). The tests read the
  reference datasets from `fast/stages/*/datasets/`.
