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

import re
from pathlib import Path

import click

HEADER = "".join(open(__file__).readlines()[2:15])
VERSIONS_TEMPLATE = """
# Fabric release: {fabric_release}

terraform {{
  required_version = ">= {engine_version}"
  required_providers {{
    google = {{
      source  = "hashicorp/google"
      version = ">= {provider_min_version}, < {provider_max_version}" # tftest
    }}
    google-beta = {{
      source  = "hashicorp/google-beta"
      version = ">= {provider_min_version}, < {provider_max_version}" # tftest
    }}
  }}
  provider_meta "google" {{
    module_name = "google-pso-tool/cloud-foundation-fabric/{path}:{fabric_release}-{engine}"
  }}
  provider_meta "google-beta" {{
    module_name = "google-pso-tool/cloud-foundation-fabric/{path}:{fabric_release}-{engine}"
  }}
}}
"""


def extract_variables(template, interpolated_string):
  # Find all variable names in the escaped template
  variable_names = re.findall(r'\{(.*?)\}', template)

  # Create a regular expression pattern to match the interpolated string within the template
  pattern = re.sub(r'\{(.*?)\}', r'(.*?)', template)
  pattern = pattern.replace("{{", "{").replace("}}", "}")
  pattern = r'.*?' + pattern + r'.*?'

  # Extract the values using the pattern
  match = re.search(pattern, interpolated_string)
  if match:
    return dict(zip(variable_names, match.groups()))


def process_file(file_path, context):
  with file_path.open("w", encoding="utf-8") as f:
    f.write(HEADER)
    f.write(VERSIONS_TEMPLATE.format(**context))


@click.command()
@click.option("--fabric-release", help="Override Fabric release version")
@click.option("--provider-min-version",
              help="Override GCP provider min version")
@click.option("--provider-max-version",
              help="Override GCP provider max version")
@click.option("--tf-version", help="Override Terraform version")
@click.option("--tofu-version", help="Override OpenTofu version")
@click.option("--write-defaults/--no-write-defaults", default=False,
              help="Also rewrite default-versions.t*f*")
def main(write_defaults, **kwargs):
  root_path = Path(__file__).parents[1]
  overrides = {k: v for k, v in kwargs.items() if v is not None}
  for engine in ["tf", "tofu"]:
    defaults_fname = root_path / f"default-versions.{engine}"
    defaults = extract_variables(VERSIONS_TEMPLATE, defaults_fname.read_text())
    context = defaults | overrides
    if kwargs[f'{engine}_version'] is not None:
      context['engine_version'] = kwargs[f'{engine}_version']

    for file_path in root_path.rglob(f"versions.{engine}"):
      click.echo(f"Processing {file_path}")
      process_file(file_path, context | {
          "path": file_path.parent.relative_to(root_path),
      })

    if write_defaults:
      click.echo(f"Processing {defaults_fname}")
      process_file(defaults_fname, context)


if __name__ == "__main__":
  main()
