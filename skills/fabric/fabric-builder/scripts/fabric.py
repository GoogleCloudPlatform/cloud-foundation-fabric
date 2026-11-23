#!/usr/bin/env python3
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Helper for Cloud Foundation Fabric modules, factories, and YAML schemas."""

import argparse
import hashlib
import json
import logging
import pathlib
import re
import shutil
import ssl
import sys
import time
import urllib.error
import urllib.request

REPO = "GoogleCloudPlatform/cloud-foundation-fabric"
API = f"https://api.github.com/repos/{REPO}"
RAW_BASE = f"https://raw.githubusercontent.com/{REPO}"
RAW_URL = f"{RAW_BASE}/master"
CACHE_DIR = pathlib.Path("/tmp/fabric_cache")
CACHE_TTL = 6 * 3600
NO_CACHE = False
NO_SSL_VERIFY = False

MODELINE_RE = re.compile(r"^\s*#\s*yaml-language-server:\s*\$schema=(.+?)\s*$",
                         re.MULTILINE)
MD_LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")


def cache_key(url):
  return hashlib.sha1(url.encode()).hexdigest()


def cache_get(url):
  if NO_CACHE:
    return None
  key = cache_key(url)
  path = CACHE_DIR / key
  if not path.is_file():
    logging.info("Cache miss for %s (key: %s)", url, key)
    return None
  try:
    entry = json.loads(path.read_text(encoding="utf-8"))
    if time.time() - entry["ts"] > CACHE_TTL:
      logging.info("Cache expired for %s (key: %s)", url, key)
      path.unlink()
      return None
    logging.info("Cache hit for %s (key: %s)", url, key)
    return entry["data"]
  except Exception:
    return None


def cache_set(url, data):
  if NO_CACHE:
    return
  key = cache_key(url)
  try:
    CACHE_DIR.mkdir(exist_ok=True)
    (CACHE_DIR / key).write_text(json.dumps({
        "ts": time.time(),
        "data": data
    }), encoding="utf-8")
    logging.info("Cached data for %s (key: %s)", url, key)
  except Exception as exc:
    logging.warning("Could not write to cache: %s", exc)


def cache_clear():
  if CACHE_DIR.is_dir():
    shutil.rmtree(CACHE_DIR)
    logging.info("Cache cleared")
  else:
    logging.info("No cache to clear")


def fetch(url, is_json=False, headers=None):
  cached = cache_get(url)
  if cached is not None:
    return cached

  logging.info("Fetching: %s", url)
  req = urllib.request.Request(url, headers=headers or {})
  ctx = ssl._create_unverified_context() if NO_SSL_VERIFY else None
  with urllib.request.urlopen(req, timeout=30, context=ctx) as resp:
    raw_data = resp.read()
    data = json.loads(raw_data) if is_json else raw_data.decode("utf-8")

  cache_set(url, data)
  return data


def api_get(path, ref=None):
  url = f"{API}/{path}"
  if ref:
    sep = "&" if "?" in url else "?"
    url = f"{url}{sep}ref={ref}"
  return fetch(url, is_json=True,
               headers={"Accept": "application/vnd.github.v3+json"})


def fetch_url(url):
  try:
    return fetch(url)
  except urllib.error.HTTPError as exc:
    if exc.code == 404:
      logging.warning("File not found: %s", url)
      return None
    raise


def list_modules(ref="master"):
  entries = api_get("contents/modules", ref=ref)
  if entries:
    print("Available Fabric Modules:")
    for entry in entries:
      if entry["type"] == "dir":
        print(f" - {entry['name']}")


def latest_release():
  rel = api_get("releases/latest")
  if rel:
    print(rel.get("tag_name"))


def _clean_md_cell(text):
  """Strip outer markdown bold markers and simplify [label](path) links."""
  text = text.strip()
  if text.startswith("**") and text.endswith("**") and len(text) > 4:
    text = text[2:-2]
  return MD_LINK_RE.sub(r"\2", text)


def parse_factories_md(md_text):
  """Parse FACTORIES.md tables into structured records by section."""
  sections = {"modules": [], "stages": [], "addons": []}
  current = None
  headers = []

  for line in md_text.splitlines():
    stripped = line.strip()
    if stripped == "## Modules":
      current = "modules"
      headers = []
      continue
    if stripped == "## FAST Stages":
      current = "stages"
      headers = []
      continue
    if stripped == "## FAST Addons & Project Templates":
      current = "addons"
      headers = []
      continue
    if stripped.startswith("## "):
      current = None
      headers = []
      continue

    if current is None or not stripped.startswith("|"):
      continue
    cells = [c.strip() for c in stripped.strip("|").split("|")]
    if all(re.fullmatch(r":?-+:?", c) for c in cells):
      continue
    if not headers:
      headers = cells
      continue
    if len(cells) != len(headers):
      continue
    row = {headers[i]: _clean_md_cell(cells[i]) for i in range(len(headers))}
    sections[current].append(row)

  return sections


def list_factories(target=None, ref="master"):
  """Surface factory modules/stages or detailed rows for one target."""
  md_text = fetch_url(f"{RAW_BASE}/{ref}/FACTORIES.md")
  if not md_text:
    raise FileNotFoundError(f"Could not fetch FACTORIES.md at ref '{ref}'")
  sections = parse_factories_md(md_text)

  if not target:
    mod_types = {}
    for row in sections["modules"]:
      name = row["Module"]
      kind = "pure" if row["Primary Module Resource"] == "N/A" else "in-module"
      mod_types.setdefault(name, kind)
    print(
        "Fabric Module Factories (run `fabric.py factories <name>` for keys and schemas):"
    )
    for name in sorted(mod_types):
      print(f" - {name} ({mod_types[name]})")

    stages = sorted({row["Stage"] for row in sections["stages"]})
    if stages:
      print("\nFAST Stage Factories:")
      for stage in stages:
        print(f" - {stage}")

    addons = sorted({row["Component"] for row in sections["addons"]})
    if addons:
      print("\nFAST Addons & Project Templates:")
      for comp in addons:
        print(f" - {comp}")
    return

  needle = target.strip().lower()
  matches = []
  for kind, key_col in (("module", "Module"), ("stage", "Stage"),
                        ("addon", "Component")):
    for row in sections["modules" if kind == "module" else "stages" if kind ==
                        "stage" else "addons"]:
      if row[key_col].lower() == needle:
        matches.append((kind, row))

  if not matches:
    for kind, key_col in (("module", "Module"), ("stage", "Stage"),
                          ("addon", "Component")):
      for row in sections["modules" if kind == "module" else "stages" if kind ==
                          "stage" else "addons"]:
        if needle in row[key_col].lower():
          matches.append((kind, row))

  if not matches:
    raise ValueError(
        f"No factory found matching '{target}'. Run `fabric.py factories` to list available targets."
    )

  for kind, row in matches:
    if kind == "module":
      print(f"[{row['Module']}] key: {row['Factory Key']}")
      print(f"  primary: {row['Primary Module Resource']}")
      print(f"  manages: {row['Factory-Managed Resources']}")
      print(f"  inputs:  {row['Dependencies (Module Variables)']}")
      print(f"  schema:  {row['Schema']}")
    else:
      label = row.get("Stage") or row.get("Component")
      print(f"[{label}] key: {row['Factory (Key/Feature)']}")
      print(f"  type:    {row['Implementation Type']}")
      print(f"  backing: {row['Underlying Module/Resource']}")
      print(f"  schema:  {row['Schema']}")


def fetch_schemas(target, is_stage=False, ref="master", out_dir=None):
  """Fetch *.schema.json files for a module or FAST stage."""
  base = (f"fast/stages/{target}/schemas"
          if is_stage else f"modules/{target}/schemas")
  entries = api_get(f"contents/{base}", ref=ref)
  schema_files = sorted(entry["name"]
                        for entry in entries
                        if entry.get("type") == "file" and
                        entry.get("name", "").endswith(".schema.json"))
  if not schema_files:
    raise FileNotFoundError(f"No *.schema.json files under {base}@{ref}")

  out_path = pathlib.Path(out_dir) if out_dir else None
  if out_path:
    out_path.mkdir(parents=True, exist_ok=True)

  fetched = []
  for name in schema_files:
    body = fetch_url(f"{RAW_BASE}/{ref}/{base}/{name}")
    if body is None:
      continue
    if out_path:
      dest = out_path / name
      dest.write_text(body, encoding="utf-8")
      fetched.append(str(dest))
    else:
      header = f"schemas/{name}" if not is_stage else f"{base}/{name}"
      print(f"<BEGIN {header}>")
      print(body.rstrip())
      print(f"<END {header}>")
      fetched.append(name)
  return fetched


def fetch_module(module, fetch_type, ref="master", is_stage=False,
                 out_dir=None):
  if fetch_type == "schemas":
    fetched = fetch_schemas(module, is_stage=is_stage, ref=ref, out_dir=out_dir)
    if out_dir:
      names = ", ".join(pathlib.Path(p).name for p in fetched)
      print(f"Saved {len(fetched)} schema(s) to {out_dir}: {names}")
    return

  entries = api_get(f"contents/modules/{module}", ref=ref)
  if not entries:
    logging.error("Module '%s' not found or empty.", module)
    return

  files = [entry["name"] for entry in entries if entry["type"] == "file"]
  if fetch_type == "readme":
    want = [f for f in files if f == "README.md"]
  elif fetch_type == "variables":
    want = [f for f in files if f.startswith("variables") and f.endswith(".tf")]
  elif fetch_type == "outputs":
    want = [f for f in files if f.startswith("output") and f.endswith(".tf")]
  else:
    want = []

  if not want:
    logging.warning("No files found for type '%s' in module '%s'.", fetch_type,
                    module)
    return

  for filename in want:
    content = fetch_url(f"{RAW_BASE}/{ref}/modules/{module}/{filename}")
    if content:
      content = re.sub(
          r"(?:/\*+\n)?^\s*(?:#|//|\*)\s*Copyright \d{4} Google LLC.*?"
          r"limitations under the License\.\n(?:\s*\*/\n)?",
          "",
          content,
          flags=re.DOTALL | re.MULTILINE,
      )
      content = content.lstrip()
      print(f"<BEGIN {filename}>")
      print(content)
      print(f"<END {filename}>")


def load_schema(uri, base_file=None, cache=None):
  """Load a JSON schema from a local path or HTTP(S) URL."""
  if uri.startswith(("http://", "https://")):
    if cache is not None and uri in cache:
      return cache[uri]
    raw = fetch(uri)
    schema = json.loads(raw) if isinstance(raw, str) else raw
    if cache is not None:
      cache[uri] = schema
    return schema

  schema_path = pathlib.Path(uri)
  if not schema_path.is_absolute() and base_file is not None:
    schema_path = (base_file.parent / schema_path).resolve()
  else:
    schema_path = schema_path.resolve()

  key = str(schema_path)
  if cache is not None and key in cache:
    return cache[key]
  if not schema_path.is_file():
    raise FileNotFoundError(f"Schema not found: {schema_path}")
  schema = json.loads(schema_path.read_text(encoding="utf-8"))
  if cache is not None:
    cache[key] = schema
  return schema


def collect_yaml_files(paths):
  """Collect .yaml/.yml files from file or directory paths."""
  found = []
  for raw in paths:
    path = pathlib.Path(raw)
    if path.is_file():
      if path.suffix in (".yaml", ".yml"):
        found.append(path)
    elif path.is_dir():
      for candidate in sorted(path.rglob("*")):
        if candidate.is_file() and candidate.suffix in (".yaml", ".yml"):
          found.append(candidate)
    else:
      raise FileNotFoundError(f"Path not found: {path}")
  return found


def validate_yaml_files(paths, schema_override=None, require_modeline=False):
  """Validate YAML files against modeline schemas or an explicit override."""
  import jsonschema
  import yaml

  files = collect_yaml_files(paths)
  cache = {}
  errors = []
  skipped = []
  checked = 0

  for file_path in files:
    try:
      content = file_path.read_text(encoding="utf-8")
    except OSError as exc:
      errors.append(f"{file_path}: read error: {exc}")
      continue

    if schema_override:
      schema_uri = schema_override
      base_file = None
    else:
      match = MODELINE_RE.search(content)
      if not match:
        if require_modeline:
          errors.append(
              f"{file_path}: missing # yaml-language-server $schema modeline")
        else:
          skipped.append(file_path)
        continue
      schema_uri = match.group(1).strip()
      base_file = file_path

    try:
      schema = load_schema(schema_uri, base_file=base_file, cache=cache)
    except Exception as exc:
      errors.append(f"{file_path}: failed to load schema '{schema_uri}': {exc}")
      continue

    try:
      docs = list(yaml.safe_load_all(content))
    except yaml.YAMLError as exc:
      errors.append(f"{file_path}: YAML parse error: {exc}")
      continue

    validator_cls = jsonschema.validators.validator_for(schema)
    try:
      validator_cls.check_schema(schema)
    except jsonschema.SchemaError as exc:
      errors.append(
          f"{file_path}: invalid schema '{schema_uri}': {exc.message}")
      continue

    validator = validator_cls(schema)
    checked += 1
    for idx, doc in enumerate(docs):
      if doc is None:
        continue
      for err in sorted(validator.iter_errors(doc), key=lambda e: list(e.path)):
        loc = ".".join(str(p) for p in err.absolute_path) or "<root>"
        errors.append(f"{file_path} (doc {idx}, {loc}): {err.message}")

  return checked, skipped, errors


def build_parser():
  parser = argparse.ArgumentParser(
      description="Cloud Foundation Fabric helper for agents")
  parser.add_argument("--clear-cache", action="store_true",
                      help="clear cache before running")
  parser.add_argument("--no-cache", action="store_true",
                      help="bypass cache and fetch from source")
  parser.add_argument("-v", "--verbose", action="store_true",
                      help="enable verbose logging")
  parser.add_argument("--no-ssl-verify", action="store_true",
                      help="bypass SSL certificate verification")

  sub = parser.add_subparsers(dest="cmd")

  p_mod = sub.add_parser("modules", help="list available modules")
  p_mod.add_argument("--ref", default="master",
                     help="Git tag or branch (default: master)")

  sub.add_parser("release", help="show latest release")

  p_fac = sub.add_parser(
      "factories", help="list factory modules/stages or inspect one target")
  p_fac.add_argument("target", nargs="?",
                     help="optional module, stage, or addon name to filter")
  p_fac.add_argument("--ref", default="master",
                     help="Git tag or branch (default: master)")

  p_fetch = sub.add_parser("fetch", help="fetch module or stage files")
  fsp = p_fetch.add_subparsers(dest="fetch_cmd", required=True)

  for name, help_text in (("readme", "fetch README.md"),
                          ("variables", "fetch variables*.tf"),
                          ("outputs", "fetch output*.tf")):
    sub_f = fsp.add_parser(name, help=help_text)
    sub_f.add_argument("module", help="module name")
    sub_f.add_argument("--ref", default="master",
                       help="Git tag or branch (default: master)")

  f_schemas = fsp.add_parser("schemas", help="fetch JSON schemas")
  f_schemas.add_argument("module", help="module or FAST stage name")
  f_schemas.add_argument("--stage", action="store_true",
                         help="fetch from fast/stages/<name>/schemas")
  f_schemas.add_argument("--ref", default="master",
                         help="Git tag or branch (default: master)")
  f_schemas.add_argument("--out",
                         help="write fetched schemas to this directory")

  p_val = sub.add_parser(
      "validate", help="validate factory YAML files against JSON schemas")
  p_val.add_argument("paths", nargs="+", help="YAML files or directories")
  p_val.add_argument("--schema", help="explicit schema path or URL override")
  p_val.add_argument("--require-modeline", action="store_true",
                     help="fail if any YAML file lacks a $schema modeline")

  return parser


def main(argv=None):
  parser = build_parser()
  args = parser.parse_args(argv)

  level = logging.INFO if args.verbose else logging.WARNING
  logging.basicConfig(level=level, format="%(levelname)s: %(message)s",
                      stream=sys.stderr)

  global NO_CACHE, NO_SSL_VERIFY
  NO_CACHE = args.no_cache
  NO_SSL_VERIFY = args.no_ssl_verify

  if args.clear_cache:
    cache_clear()

  try:
    if args.cmd == "modules":
      list_modules(ref=args.ref)
    elif args.cmd == "release":
      latest_release()
    elif args.cmd == "factories":
      list_factories(target=args.target, ref=args.ref)
    elif args.cmd == "fetch":
      fetch_module(
          args.module,
          args.fetch_cmd,
          ref=args.ref,
          is_stage=getattr(args, "stage", False),
          out_dir=getattr(args, "out", None),
      )
    elif args.cmd == "validate":
      checked, skipped, errors = validate_yaml_files(
          args.paths,
          schema_override=args.schema,
          require_modeline=args.require_modeline,
      )
      if skipped:
        print(f"Skipped {len(skipped)} file(s) without $schema modeline.")
      if errors:
        print("YAML schema validation failed:", file=sys.stderr)
        for err in errors:
          print(f" - {err}", file=sys.stderr)
        return 1
      print(f"Validated {checked} YAML file(s) successfully.")
    else:
      parser.print_help()
    return 0
  except (OSError, urllib.error.URLError, ValueError) as exc:
    print(f"Error: {exc}", file=sys.stderr)
    return 1


if __name__ == "__main__":
  sys.exit(main())
