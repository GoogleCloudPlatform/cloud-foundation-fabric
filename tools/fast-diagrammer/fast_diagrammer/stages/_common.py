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
"""Helpers shared by the stage builders.

Element ids, badge budgets, text fitting and legend rows live here so that
every stage applies the same rules. Text helpers never cut an identifier: a
list is shortened by dropping whole items (`a, b, +3`), free text is shortened
with a trailing ellipsis, and cards grow to fit identifiers instead.
"""

from typing import Iterable, List, Optional

import warnings

from ..scene.model import Badge, LegendEntry, resolve_color
from ..yamlio import DatasetWarning

__all__ = [
    "BILLING_EXPORT_DATASET",
    "ELLIPSIS",
    "MAX_CARD_BADGES_DEFAULT",
    "MAX_ZONE_BADGES_DEFAULT",
    "SCC_AGENT_NAMES",
    "SECONDARY_NAME_HINTS",
    "VPC_ROLE_BY_NAME",
    "cap_badges",
    "card_width_for",
    "cid",
    "ellipsize",
    "join_limited",
    "legend_card",
    "legend_edge",
    "warn",
]

# Default badge budgets; `verbose_badges=True` lifts them.
MAX_CARD_BADGES_DEFAULT = 4
MAX_ZONE_BADGES_DEFAULT = 6

ELLIPSIS = "\u2026"

# Name heuristics. Builders consult these tables only when the dataset carries
# no structural signal for the same fact; each table is the complete list of
# names a builder interprets.

# 2-networking: left-to-right rank of a VPC inside a core project by VPC key
# (0 hybrid/egress, 1 transit hub; any other key is a spoke). Used after the
# structural rules (links to on-premises, masquerading NVA NICs, two or more
# peered/VPN-linked VPCs) found nothing.
VPC_ROLE_BY_NAME = {"dmz": 0, "routing": 0, "hub": 1, "transit": 1}

# 2-networking: element keys containing one of these words are drawn as the
# secondary router appliance path, used only when the dataset defines no
# `context.locations.primary` to compare regions against.
SECONDARY_NAME_HINTS = ("secondary",)

# 0-org-setup: BigQuery dataset key FAST uses for the billing export. The
# export itself is configured outside Terraform, so a project declaring this
# dataset is the only signal for the billing export edge.
BILLING_EXPORT_DATASET = "billing_export"

# 1-vpcsc: organization service agents that belong to Security Command
# Center; a grouped agents card is titled "SCC service agents" only when
# every agent in the group is listed here.
SCC_AGENT_NAMES = frozenset({
    "csc-hpsa",
    "ktd-hpsa",
    "security-center-api",
})

# Approximate glyph advance of the card title (12.5 px bold) and subtitle
# (10.5 px) fonts, and the horizontal space taken by the icon and padding.
_TITLE_PX_PER_CHAR = 7.4
_SUBTITLE_PX_PER_CHAR = 6.0
_CARD_TEXT_OVERHEAD = 60.0


def cid(prefix: str, *parts: object) -> str:
  """Returns a stable element id: ASCII letters/digits, everything else `_`.

  `None` and empty parts are skipped. Distinct keys that differ only in
  punctuation (`a-b`, `a_b`) map to the same id; `SceneGraph.add_*` rejects
  the duplicate instead of writing a corrupt file.
  """
  raw = "_".join([prefix] +
                 [str(p) for p in parts if p is not None and str(p) != ""])
  return "".join(ch if (ch.isascii() and ch.isalnum()) else "_" for ch in raw)


def cap_badges(badges: List[Badge], limit: int, verbose: bool) -> List[Badge]:
  """Keeps the first `limit - 1` badges and folds the rest into `+N`."""
  if verbose or len(badges) <= limit:
    return list(badges)
  if limit <= 1:
    return [Badge(text=f"+{len(badges)}", tone="neutral")]
  kept = list(badges[:limit - 1])
  kept.append(Badge(text=f"+{len(badges) - (limit - 1)}", tone="neutral"))
  return kept


def ellipsize(text: str, limit: int) -> str:
  """Shortens free text to `limit` characters with a trailing ellipsis.

  Use only for prose (descriptions); identifiers must never go through it.
  """
  text = str(text or "")
  if limit <= 0 or len(text) <= limit:
    return text
  return text[:max(1, limit - 1)].rstrip() + ELLIPSIS


def join_limited(items: Iterable[object], limit: int, sep: str = ", ",
                 empty: str = "") -> str:
  """Joins whole items until `limit` characters, then appends `+N`.

  The first item is always shown in full, so an identifier is never cut.
  """
  values = [str(i) for i in items]
  if not values:
    return empty
  out = [values[0]]
  for idx, val in enumerate(values[1:], start=1):
    remaining = len(values) - idx
    candidate = sep.join(out + [val])
    suffix = f"{sep}+{remaining - 1}" if remaining > 1 else ""
    if len(candidate) + len(suffix) > limit:
      out.append(f"+{remaining}")
      return sep.join(out)
    out.append(val)
  return sep.join(out)


def card_width_for(title: str, subtitle: str = "",
                   min_width: float = 248.0) -> float:
  """Returns a card width that fits `title` and `subtitle` on one line each."""
  need = max(
      len(title or "") * _TITLE_PX_PER_CHAR,
      len(subtitle or "") * _SUBTITLE_PX_PER_CHAR) + _CARD_TEXT_OVERHEAD
  return float(max(min_width, round(need)))


def legend_edge(label: str, color: str, dash: str = "solid",
                head: str = "filled") -> LegendEntry:
  """Legend row for an edge style; `color` is the `$Token` the edge uses."""
  return LegendEntry(label=label, kind="edge", color=resolve_color(color),
                     dash=dash, head=head)


def legend_card(label: str, color: str, fill: str = "#ffffff",
                dashed: bool = False) -> LegendEntry:
  """Legend row for a card swatch; colours accept `$Token`s."""
  return LegendEntry(label=label, kind="card", color=resolve_color(color),
                     fill=resolve_color(fill), dashed=dashed)


def warn(sink: Optional[object], message: str) -> None:
  """Reports a non-fatal dataset problem found by a builder.

  Appends to `sink.warnings` when the object carries such a list, otherwise
  emits a `yamlio.DatasetWarning` like the loaders do, so callers collect
  loader and builder warnings the same way.
  """
  bucket = getattr(sink, "warnings", None)
  if isinstance(bucket, list):
    if message not in bucket:
      bucket.append(message)
    return
  warnings.warn(DatasetWarning(message), stacklevel=3)
