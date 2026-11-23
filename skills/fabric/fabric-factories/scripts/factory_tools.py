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
"""Validate Fabric factory YAML files and fetch schemas from GitHub."""

import argparse
import json
import pathlib
import re
import ssl
import sys
import urllib.error
import urllib.request

REPO = "GoogleCloudPlatform/cloud-foundation-fabric"
API = f"https://api.github.com/repos/{REPO}"
MODELINE_RE = re.compile(r"^\s*#\s*yaml-language-server:\s*\$schema=(.+?)\s*$",
                         re.MULTILINE)


def _ssl_context(no_ssl_verify):
  return ssl._create_unverified_context() if no_ssl_verify else None


def _http_get(url, headers=None, no_ssl_verify=False):
  req = urllib.request.Request(url, headers=headers or {})
  with urllib.request.urlopen(req, timeout=30,
                              context=_ssl_context(no_ssl_verify)) as resp:
    return resp.read().decode("utf-8")


def load_schema(uri, base_file=None, cache=None, no_ssl_verify=False):
  """Load a JSON schema from a local path or HTTP(S) URL."""
  if uri.startswith(("http://", "https://")):
    key = uri
    if cache is not None and key in cache:
      return cache[key]
    raw = _http_get(uri, no_ssl_verify=no_ssl_verify)
    schema = json.loads(raw)
    if cache is not None:
      cache[key] = schema
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
  """Collect .yaml/.yml files from the given file or directory paths."""
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


def validate_yaml_files(paths, schema_override=None, require_modeline=False,
                        no_ssl_verify=False):
  """Validate YAML files against modeline schemas or an explicit override.

  Returns a tuple of (checked_count, skipped_files, errors).
  """
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
          errors.append(f"{file_path}: missing # yaml-language-server $schema "
                        "modeline")
        else:
          skipped.append(file_path)
        continue
      schema_uri = match.group(1).strip()
      base_file = file_path

    try:
      schema = load_schema(schema_uri, base_file=base_file, cache=cache,
                           no_ssl_verify=no_ssl_verify)
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
      errors.append(f"{file_path}: invalid schema '{schema_uri}': "
                    f"{exc.message}")
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


def fetch_schemas(target, is_stage=False, ref="master", out_dir=None,
                  no_ssl_verify=False):
  """Fetch *.schema.json files for a Fabric module or FAST stage from GitHub."""
  base = f"fast/stages/{target}/schemas" if is_stage else f"modules/{target}/schemas"
  api_url = f"{API}/contents/{base}?ref={ref}"
  headers = {"Accept": "application/vnd.github.v3+json"}
  entries = json.loads(
      _http_get(api_url, headers=headers, no_ssl_verify=no_ssl_verify))
  schema_files = sorted(
      e["name"]
      for e in entries
      if e.get("type") == "file" and e.get("name", "").endswith(".schema.json"))
  if not schema_files:
    raise FileNotFoundError(f"No *.schema.json files under {base}@{ref}")

  raw_base = f"https://raw.githubusercontent.com/{REPO}/{ref}/{base}"
  out_path = pathlib.Path(out_dir) if out_dir else None
  if out_path:
    out_path.mkdir(parents=True, exist_ok=True)

  fetched = []
  for name in schema_files:
    body = _http_get(f"{raw_base}/{name}", no_ssl_verify=no_ssl_verify)
    if out_path:
      dest = out_path / name
      dest.write_text(body, encoding="utf-8")
      fetched.append(str(dest))
    else:
      print(f"<BEGIN {base}/{name}>")
      print(body.rstrip())
      print(f"<END {base}/{name}>")
      fetched.append(name)
  return fetched


def latest_release(no_ssl_verify=False):
  """Return the latest Fabric release tag name from GitHub."""
  headers = {"Accept": "application/vnd.github.v3+json"}
  data = json.loads(
      _http_get(f"{API}/releases/latest", headers=headers,
                no_ssl_verify=no_ssl_verify))
  return data.get("tag_name", "")


def main(argv=None):
  parser = argparse.ArgumentParser(
      description="Cloud Foundation Fabric YAML factory helper.")
  parser.add_argument("--no-ssl-verify", action="store_true",
                      help="Disable TLS certificate verification.")
  sub = parser.add_subparsers(dest="cmd", required=True)

  p_val = sub.add_parser("validate",
                         help="Validate YAML files against JSON schemas.")
  p_val.add_argument("paths", nargs="+", help="YAML files or directories.")
  p_val.add_argument("--schema", help="Explicit schema path or URL override.")
  p_val.add_argument("--require-modeline", action="store_true",
                     help="Fail if any YAML file lacks a $schema modeline.")

  p_fetch = sub.add_parser("fetch",
                           help="Fetch JSON schemas for a module or stage.")
  p_fetch.add_argument("target", help="Module name or FAST stage name.")
  p_fetch.add_argument("--stage", action="store_true",
                       help="Fetch from fast/stages/<target>/schemas.")
  p_fetch.add_argument("--ref", default="master",
                       help="Git tag or branch (default: master).")
  p_fetch.add_argument("--out", help="Write fetched schemas to this directory.")

  sub.add_parser("release", help="Print the latest Fabric release tag.")

  args = parser.parse_args(argv)

  try:
    if args.cmd == "validate":
      checked, skipped, errors = validate_yaml_files(
          args.paths,
          schema_override=args.schema,
          require_modeline=args.require_modeline,
          no_ssl_verify=args.no_ssl_verify,
      )
      if skipped:
        print(f"Skipped {len(skipped)} file(s) without $schema modeline.")
      if errors:
        print("YAML schema validation failed:", file=sys.stderr)
        for err in errors:
          print(f" - {err}", file=sys.stderr)
        return 1
      print(f"Validated {checked} YAML file(s) successfully.")
      return 0

    if args.cmd == "fetch":
      fetched = fetch_schemas(args.target, is_stage=args.stage, ref=args.ref,
                              out_dir=args.out,
                              no_ssl_verify=args.no_ssl_verify)
      if args.out:
        print(f"Saved {len(fetched)} schema(s) to {args.out}: "
              f"{', '.join(pathlib.Path(p).name for p in fetched)}")
      return 0

    if args.cmd == "release":
      print(latest_release(no_ssl_verify=args.no_ssl_verify))
      return 0
  except (OSError, urllib.error.URLError, ValueError) as exc:
    print(f"Error: {exc}", file=sys.stderr)
    return 1
  return 0


if __name__ == "__main__":
  sys.exit(main())
