# 2-networking goldens

Regression contract of this tool for `fast_diagrammer/stages/networking.py`
and the rendering core (`fast_diagrammer/scene/*`): any change that alters a
byte of a 2-networking diagram fails the tests until the goldens are bumped.

- `expected/<key>.drawio`, `expected/<key>.drawio.svg`: the 12 diagrams
  (6 datasets × `topology`, `dns`) as rendered by this tool.
- `inputs/<key>.scene.json`: pre-layout `SceneGraph` snapshots
  (`fast_diagrammer.scene.serialize`) of `stages.networking.build` for the
  same keys. Rendering a snapshot reproduces `expected/` byte for byte.
- `SHA256SUMS`: checksums of every file above.

Datasets: `classic` (a symlink to `hub-and-spokes-peerings`, kept under its
own name), `hub-and-spokes-ncc`, `hub-and-spokes-nva`,
`hub-and-spokes-nva-ncc`, `hub-and-spokes-peerings` and
`hub-and-spokes-vpns`, all from `fast/stages/2-networking/datasets/`.

Gates: `tests/test_parity_networking.py` (builder vs snapshot, builder and
snapshot renders vs `expected/`) and `tests/test_layout_gates.py`
(checksums, engine parity, determinism, no overlaps).

Regenerate only in a reviewed bump, from the repository root, and say in the
commit message why the pictures changed:

```bash
python3 tools/fast-diagrammer/tools/update_goldens.py --check   # list drift
python3 tools/fast-diagrammer/tools/update_goldens.py           # rewrite
```
