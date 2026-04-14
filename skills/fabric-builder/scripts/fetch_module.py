#!/usr/bin/env python3
# Copyright 2025 Google LLC
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

import urllib.request
import json
import sys
import argparse

REPO_URL = "https://api.github.com/repos/GoogleCloudPlatform/cloud-foundation-fabric"
RAW_URL = "https://raw.githubusercontent.com/GoogleCloudPlatform/cloud-foundation-fabric/master"


def list_modules():
  """Fetches and prints the list of available modules from the GitHub repository."""
  url = f"{REPO_URL}/contents/modules"
  req = urllib.request.Request(
      url, headers={'Accept': 'application/vnd.github.v3+json'})
  try:
    with urllib.request.urlopen(req) as response:
      data = json.loads(response.read().decode('utf-8'))
      print("Available Fabric Modules:")
      for item in data:
        if item['type'] == 'dir':
          print(f" - {item['name']}")
  except Exception as e:
    print(f"Error fetching modules: {e}", file=sys.stderr)


def fetch_module_readme(module_name):
  """Fetches the README.md for a specific module, containing variables, outputs, and examples."""
  url = f"{RAW_URL}/modules/{module_name}/README.md"
  try:
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as response:
      content = response.read().decode('utf-8')
      print(f"--- README.md for module '{module_name}' ---\n")
      print(content)
  except urllib.error.HTTPError as e:
    if e.code == 404:
      print(f"Module '{module_name}' not found or has no README.md.",
            file=sys.stderr)
    else:
      print(f"Error fetching README for {module_name}: {e}", file=sys.stderr)
  except Exception as e:
    print(f"Error fetching README for {module_name}: {e}", file=sys.stderr)


def fetch_latest_release():
  """Fetches the latest release version from the GitHub repository."""
  url = f"{REPO_URL}/releases/latest"
  req = urllib.request.Request(
      url, headers={'Accept': 'application/vnd.github.v3+json'})
  try:
    with urllib.request.urlopen(req) as response:
      data = json.loads(response.read().decode('utf-8'))
      print(data.get('tag_name', 'No tag_name found'))
  except Exception as e:
    print(f"Error fetching latest release: {e}", file=sys.stderr)


def fetch_module_files(module_name, file_prefix):
  """Fetches files starting with file_prefix for a specific module."""
  url = f"{REPO_URL}/contents/modules/{module_name}"
  req = urllib.request.Request(
      url, headers={'Accept': 'application/vnd.github.v3+json'})
  try:
    with urllib.request.urlopen(req) as response:
      data = json.loads(response.read().decode('utf-8'))
      for item in data:
        if item['type'] == 'file' and item['name'].startswith(
            file_prefix) and item['name'].endswith('.tf'):
          file_name = item['name']
          print(f"--- {file_name} for module '{module_name}' ---\n")
          raw_file_url = f"{RAW_URL}/modules/{module_name}/{file_name}"
          try:
            with urllib.request.urlopen(raw_file_url) as raw_response:
              content = raw_response.read().decode('utf-8')
              print(content)
              print("\n" + "=" * 40 + "\n")
          except Exception as e:
            print(f"Error fetching content for {file_name}: {e}",
                  file=sys.stderr)
  except Exception as e:
    print(f"Error listing contents for {module_name}: {e}", file=sys.stderr)


if __name__ == "__main__":
  parser = argparse.ArgumentParser(
      description="Fetch info about Cloud Foundation Fabric modules from GitHub."
  )
  parser.add_argument(
      "module", nargs="?", help=
      "Name of the module to fetch (e.g., 'project'). If omitted, lists all modules."
  )
  parser.add_argument("--latest-release", action="store_true",
                      help="Fetch the latest release version.")
  parser.add_argument("--variables", action="store_true",
                      help="Fetch variables files for the module.")
  parser.add_argument("--outputs", action="store_true",
                      help="Fetch outputs files for the module.")

  args = parser.parse_args()

  if args.latest_release:
    fetch_latest_release()

  if args.module:
    if args.variables or args.outputs:
      if args.variables:
        fetch_module_files(args.module, "variables")
      if args.outputs:
        fetch_module_files(args.module, "outputs")
    else:
      fetch_module_readme(args.module)
  elif not args.latest_release:
    list_modules()
