# 2-networking goldens

Byte-parity contract for `fast_diagrammer/scene/*` and
`fast_diagrammer/stages/networking.py`.

- `expected/<key>.drawio`, `expected/<key>.drawio.svg`: the 12 diagrams
  (6 datasets × `topology`, `dns`), frozen from the original prototype
  engine before it was ported into this package and never regenerated since.
- `inputs/<key>.scene.json`: pre-layout `SceneGraph` snapshots
  (`fast_diagrammer.scene.serialize`) of `stages.networking.build` for the
  same keys. Rendering a snapshot reproduces `expected/` byte for byte.
- `SHA256SUMS`: checksums of every file above.

Datasets: `classic`, `hub-and-spokes-ncc`, `hub-and-spokes-nva`,
`hub-and-spokes-peerings`, `hub-and-spokes-vpns` from
`fast/stages/2-networking/datasets/`, and `hub-and-spokes-nva-ncc` vendored
under `tests/fixtures/datasets/2-networking/`.

Gates: `tests/test_parity_networking.py` (builder vs snapshot, builder and
snapshot renders vs `expected/`) and `tests/test_layout_gates.py`
(checksums, engine parity, determinism, no overlaps).

Change these files only in a reviewed golden bump:
`python3 tools/update_goldens.py` (or `--check` to see the drift), and say
why in the commit message.
