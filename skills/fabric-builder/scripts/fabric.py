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
"""Download modules from Google Cloud Foundation Fabric via GitHub API."""

import argparse
import hashlib
import json
import pathlib
import shutil
import sys
import time
import urllib.request
import urllib.error
import logging
import re

REPO = "GoogleCloudPlatform/cloud-foundation-fabric"
API = f"https://api.github.com/repos/{REPO}"
RAW_URL = f"https://raw.githubusercontent.com/{REPO}/master"
CACHE_DIR = pathlib.Path("/tmp/fabric_cache")
CACHE_TTL = 6 * 3600
NO_CACHE = False


def cache_key(url):
  return hashlib.sha1(url.encode()).hexdigest()


def cache_get(url):
  if NO_CACHE:
    return None
  key = cache_key(url)
  path = CACHE_DIR / key
  if not path.is_file():
    logging.info(f"Cache miss for {url} (key: {key})")
    return None
  try:
    entry = json.loads(path.read_text())
    if time.time() - entry["ts"] > CACHE_TTL:
      logging.info(f"Cache expired for {url} (key: {key})")
      path.unlink()
      return None
    logging.info(f"Cache hit for {url} (key: {key})")
    return entry["data"]
  except Exception:
    return None


def cache_set(url, data):
  if NO_CACHE:
    return
  key = cache_key(url)
  try:
    CACHE_DIR.mkdir(exist_ok=True)
    (CACHE_DIR / key).write_text(json.dumps({"ts": time.time(), "data": data}))
    logging.info(f"Cached data for {url} (key: {key})")
  except Exception as e:
    logging.warning(f"Could not write to cache: {e}")


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

  logging.info(f"Fetching: {url}")
  req = urllib.request.Request(url, headers=headers or {})
  with urllib.request.urlopen(req, timeout=30) as r:
    raw_data = r.read()
    data = json.loads(raw_data) if is_json else raw_data.decode("utf-8")

  cache_set(url, data)
  return data


def api_get(path):
  url = f"{API}/{path}"
  try:
    return fetch(url, is_json=True,
                 headers={"Accept": "application/vnd.github.v3+json"})
  except urllib.error.HTTPError as e:
    sys.exit(f"API Error ({e.code}): {e.reason}")
  except Exception as e:
    sys.exit(f"Error accessing API: {e}")


def fetch_url(url):
  try:
    return fetch(url)
  except urllib.error.HTTPError as e:
    if e.code == 404:
      logging.warning(f"File not found: {url}")
      return None
    sys.exit(f"HTTP Error ({e.code}) fetching {url}")
  except Exception as e:
    sys.exit(f"Error fetching {url}: {e}")


def list_modules():
  entries = api_get("contents/modules")
  if entries:
    print("Available Fabric Modules:")
    for e in entries:
      if e["type"] == "dir":
        print(f" - {e['name']}")


def latest_release():
  r = api_get("releases/latest")
  if r:
    print(r.get('tag_name'))


def fetch_module(module, fetch_type):
  entries = api_get(f"contents/modules/{module}")
  if not entries:
    logging.error(f"Module '{module}' not found or empty.")
    return

  files = [e["name"] for e in entries if e["type"] == "file"]

  if fetch_type == "readme":
    want = [f for f in files if f == "README.md"]
  elif fetch_type == "variables":
    want = [f for f in files if f.startswith("variables") and f.endswith(".tf")]
  elif fetch_type == "outputs":
    want = [f for f in files if f.startswith("output") and f.endswith(".tf")]
  elif fetch_type == "schemas":
    # Check if schemas directory exists
    has_schemas = any(
        e["name"] == "schemas" and e["type"] == "dir" for e in entries)
    if not has_schemas:
      logging.warning(f"No schemas directory found in module '{module}'.")
      return

    schema_entries = api_get(f"contents/modules/{module}/schemas")
    if not schema_entries:
      logging.error(f"Could not list schemas for module '{module}'.")
      return

    schema_files = [
        e["name"]
        for e in schema_entries
        if e["type"] == "file" and e["name"].endswith(".schema.json")
    ]
    if not schema_files:
      logging.warning(f"No schema files found in module '{module}/schemas'.")
      return

    want = [f"schemas/{f}" for f in schema_files]
  else:
    want = []

  if not want:
    logging.warning(
        f"No files found for type '{fetch_type}' in module '{module}'.")
    return

  for f in want:
    content = fetch_url(f"{RAW_URL}/modules/{module}/{f}")
    if content:
      # Strip copyright header
      content = re.sub(
          r"(?:/\*+\n)?^\s*(?:#|//|\*)\s*Copyright \d{4} Google LLC.*?limitations under the License\.\n(?:\s*\*/\n)?",
          "", content, flags=re.DOTALL | re.MULTILINE)
      # Strip leading newlines left after removing header
      content = content.lstrip()
      print(f"<BEGIN {f}>")
      print(content)
      print(f"<END {f}>")


def main():
  p = argparse.ArgumentParser(
      description="Cloud Foundation Fabric helper for agents")
  sp = p.add_subparsers(dest="cmd")

  sp.add_parser("modules", help="list available modules")
  sp.add_parser("release", help="show latest release")

  p.add_argument("--clear-cache", action="store_true",
                 help="clear cache before running")
  p.add_argument("--no-cache", action="store_true",
                 help="bypass cache and fetch from source")
  p.add_argument("-v", "--verbose", action="store_true",
                 help="enable verbose logging")

  fm = sp.add_parser("fetch", help="fetch module files to stdout")
  fsp = fm.add_subparsers(dest="fetch_cmd", required=True)

  f_readme = fsp.add_parser("readme", help="fetch README.md")
  f_readme.add_argument("module", help="module name")

  f_vars = fsp.add_parser("variables", help="fetch variables*.tf")
  f_vars.add_argument("module", help="module name")

  f_outputs = fsp.add_parser("outputs", help="fetch output*.tf")
  f_outputs.add_argument("module", help="module name")

  f_schemas = fsp.add_parser("schemas", help="fetch JSON schemas")
  f_schemas.add_argument("module", help="module name")

  args = p.parse_args()

  level = logging.INFO if args.verbose else logging.WARNING
  logging.basicConfig(level=level, format='%(levelname)s: %(message)s',
                      stream=sys.stderr)

  global NO_CACHE
  NO_CACHE = args.no_cache

  if args.clear_cache:
    cache_clear()

  if args.cmd == "modules":
    list_modules()
  elif args.cmd == "release":
    latest_release()
  elif args.cmd == "fetch":
    fetch_module(args.module, args.fetch_cmd)
  else:
    p.print_help()


if __name__ == "__main__":
  main()
