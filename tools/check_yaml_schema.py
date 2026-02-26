#!/usr/bin/env python3

# Copyright 2025 Google LLC
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
'''Check YAML files against schemas defined in modelines.'''

import json
import os
import pathlib
import re
import sys
import yaml

import click
import jsonschema
import requests

# Regex for the modeline
MODELINE_RE = re.compile(r'^\s*#\s*yaml-language-server:\s*\$schema=(.*)\s*$',
                         re.MULTILINE)


def load_schema(uri, base_path):
  """Load a schema from a URI (URL or file path)."""
  if uri.startswith('http://') or uri.startswith('https://'):
    try:
      response = requests.get(uri)
      response.raise_for_status()
      return response.json()
    except Exception as e:
      return None
  else:
    # Local file
    schema_path = pathlib.Path(uri)
    if not schema_path.is_absolute():
      schema_path = base_path.parent / schema_path

    if not schema_path.exists():
      return None

    try:
      with open(schema_path, 'r') as f:
        return json.load(f)
    except json.JSONDecodeError:
      try:
        with open(schema_path, 'r') as f:
          return yaml.safe_load(f)
      except Exception:
        return None
    except Exception:
      return None


@click.command()
@click.argument('paths', type=str, nargs=-1)
@click.option('--verbose', is_flag=True,
              help='Print files with no schema definition.')
def main(paths, verbose):
  """Validate YAML files against schemas defined in modelines."""
  files_to_check = []

  # Collect files
  for path in paths:
    path = pathlib.Path(path)
    if path.is_file():
      if path.suffix in ('.yaml', '.yml'):
        files_to_check.append(path)
    elif path.is_dir():
      for p in path.rglob('*'):
        if p.is_file() and p.suffix in ('.yaml', '.yml'):
          files_to_check.append(p)

  errors = []

  for file_path in files_to_check:
    try:
      with open(file_path, 'r') as f:
        content = f.read()

      match = MODELINE_RE.search(content)
      if match:
        schema_uri = match.group(1).strip()
        schema = load_schema(schema_uri, file_path)

        if schema:
          # Parse YAML content
          try:
            # Validate all documents in the file
            docs = list(yaml.safe_load_all(content))
            for i, doc in enumerate(docs):
              if doc is None:
                continue  # Skip empty docs
              try:
                jsonschema.validate(instance=doc, schema=schema)
              except jsonschema.ValidationError as e:
                errors.append(
                    f"{file_path} (doc {i}): Validation Error: {e.message}")
              except jsonschema.SchemaError as e:
                errors.append(
                    f"{file_path} (doc {i}): Schema Error: {e.message}")
          except yaml.YAMLError as e:
            errors.append(f"{file_path}: Invalid YAML - {e}")
        else:
          errors.append(f"{file_path}: Could not load schema {schema_uri}")
      else:
        if verbose:
          print(f"Skipping {file_path}: No schema defined.")

    except Exception as e:
      errors.append(f"{file_path}: Error processing file - {e}")

  if errors:
    print("Validation failed for the following files:")
    for error in errors:
      print(f" - {error}")
    sys.exit(1)


if __name__ == "__main__":
  main()
