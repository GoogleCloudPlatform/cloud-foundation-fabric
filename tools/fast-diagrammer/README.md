# fast-net-diagrammer

Deterministic diagram generator for Cloud Foundation Fabric FAST stage
datasets. It reads a dataset directory, builds a stage-agnostic scene graph in
plain Python, lays it out with a small flexbox engine, routes every edge
orthogonally with zero overlaps, and writes two files per view:

- `<dataset>-<view>.drawio.svg`: an SVG that also embeds the draw.io model
  (open it in a browser, or edit it in diagrams.net);
- `<dataset>-<view>.drawio`: the standalone draw.io model.

The package is `fast_diagrammer/` (Python 3.10+, stdlib plus `PyYAML`).

| Stage | Views | What the diagram answers |
|---|---|---|
| `0-org-setup` | `hierarchy` | Where folders and projects live (exact project-factory parent rules), what each core project is for (≤4 badges), which org-level controls exist, billing account, log sink / billing export / Shared VPC edges. |
| `1-vpcsc` | `perimeters` | What is inside each perimeter, enforced or dry-run, who can get in (ingress), who can get out (egress), under which access level. Stage-generated sets are dashed "set" cards with provenance. |
| `2-networking` | `topology`, `dns` | Projects → VPCs → routers, VPN/VLAN, NCC, NVAs, peerings (topology); zones, resolvers, bind/peer/forward chains (dns). Byte-identical to the frozen goldens. |

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
pip install -r tools/fast-diagrammer/requirements.txt     # PyYAML only

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

# Tests
python3 -m pytest tools/fast-diagrammer/tests
```

## CLI

| Argument / env | Default | Description |
|---|---|---|
| `INPUT_DIR` (positional), `-i/--input DIR`, `--dataset DIR` | one input required | A dataset (`.../datasets/classic`), a datasets folder (`.../datasets`) or a stage folder (`fast/stages/0-org-setup`). Folders render every dataset inside; sub-directories that are not datasets are skipped. |
| `--datasets-root DIR` | | Directory whose sub-directories are datasets. |
| `--fast-root DIR` | | FAST `stages/` directory: every `*/datasets/*` of the supported stages (the stage comes from the stage directory name), written to `<out>/<stage>/`. |
| `OUT_DIR` (second positional), `-o/--out-dir DIR` | required | Output directory. Inputs are never written. |
| `-t/--type`, `-s/--stage` | `auto` | `org-setup` / `org` / `0-org-setup`, `vpc-sc` / `vpcsc` / `1-vpcsc`, `net` / `networking` / `2-networking`; `auto` uses fingerprint detection. |
| `--views a,b` | all views of the stage | Subset of views to render. |
| `--org-dataset DIR` | unset | 1-vpcsc: resolve `logging_project`, `org_setup_projects` and sink identities from a 0-org-setup dataset. |
| `--verbose-badges` | off | Lift the default badge budget (4 per card, 6 per zone header). |
| `--legend` / `--no-legend` | on | 0-org-setup / 1-vpcsc: force the bottom-left legend on or off (2-networking has no legend, so its output stays byte-identical). |
| `--rpz-bind-lines` | off | 2-networking dns: draw explicit dashed `Bind (RPZ)` edges. |
| `--strict` | off | Non-zero exit on unknown icons (stages 0/1) or unresolved `$ns:key` sets. |
| `--rasterizer "CMD {svg} {png}"` / `FD_RASTERIZER` | unset | Optional PNG step; a failure is a warning. PNG is never required. |
| `FD_FABRIC_ROOT` | repo root, then `~/git/cloud-foundation-fabric` | Fabric checkout used by the tests to find the reference datasets. |

Stage detection (first match wins): `perimeters/` or `restricted-services.yaml`
→ `1-vpcsc`; `organization/` or `folders/` → `0-org-setup` (`starter-gcd` also
has `vpcs/`, rendered as embedded VPCs); `vpcs/` → `2-networking`.

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
  1.2 semantics (`NO` stays a string, dates stay strings).
- `fast_diagrammer/icons/`: vendored SVGs and `icons.json`, built by
  `tools/build_icons.py` (`--check` in the gate). The 13 legacy networking
  glyphs are kept verbatim; the 24 org-setup / VPC-SC glyphs are original
  drawings made for this tool, not the official Google Cloud icon set.
- `__main__.py`, `fast_diagrammer.py`: entry points for `python3 <dir>` and
  `./fast_diagrammer.py`.
- `tests/`: `test_layout_gates.py` (core),
  `test_parity_networking.py`, `test_org_setup.py`, `test_vpcsc.py`,
  `golden/2-networking/` (frozen byte-parity goldens and pre-layout scene
  snapshots, see its `README.md`; regenerate only in a reviewed bump with
  `tools/update_goldens.py`),
  `fixtures/datasets/2-networking/hub-and-spokes-nva-ncc/` (vendored from
  cff-ncc-ra, not yet in Fabric).
