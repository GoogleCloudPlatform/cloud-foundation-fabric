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
"""FAST context tokens: `$type:key` strings used as foreign keys in datasets.

Helpers to parse (`parse`, `key_of`, `split_path`) and build (`format_token`
and the networking constructors) tokens such as `$networks:hub`.
"""

import re
from typing import Optional, Tuple, List

_TOKEN = re.compile(r"^\$([a-z_]+):(.+)$")


def parse(value) -> Optional[Tuple[str, str]]:
  """Returns (type, key) for a token string, else None."""
  if not isinstance(value, str):
    return None
  m = _TOKEN.match(value)
  return (m.group(1), m.group(2)) if m else None


def is_token(value) -> bool:
  return parse(value) is not None


def key_of(value, expected_type: str) -> Optional[str]:
  """Returns the key when value is a token of expected_type, else None."""
  parsed = parse(value)
  if parsed and parsed[0] == expected_type:
    return parsed[1]
  return None


def format_token(token_type: str, key: str) -> str:
  return f"${token_type}:{key}"


def network(vpc_key: str) -> str:
  return f"$networks:{vpc_key}"


def project(project_key: str) -> str:
  return f"$project_ids:{project_key}"


def router(vpc_key: str, router_name: str) -> str:
  return f"$routers:{vpc_key}/{router_name}"


def subnet(vpc_key: str, region: str, subnet_name: str) -> str:
  return f"$subnets:{vpc_key}/{region}/{subnet_name}"


def vpn_gateway(vpc_key: str, vpn_name: str) -> str:
  return f"$vpn_gateways:{vpc_key}/{vpn_name}"


def ncc_hub(hub_key: str) -> str:
  return f"$ncc_hubs:{hub_key}"


def ncc_group(hub_key: str, group_name: str) -> str:
  return f"$ncc_groups:{hub_key}/{group_name}"


def split_path(key: str, parts: int) -> Optional[List[str]]:
  """Splits 'a/b/c' into exactly `parts` components or returns None."""
  pieces = key.split("/")
  return pieces if len(pieces) == parts else None
