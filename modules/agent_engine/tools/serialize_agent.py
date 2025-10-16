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

import argparse
import cloudpickle
import importlib.util
import os
import sys
from google.adk.agents import LlmAgent

def serialize_agent_from_file(input_file, variable_name, output_file):
    """
    Dynamically loads a Python module from a full file path, accesses a
    top-level variable containing an agent object, and serializes that object
    to a specified output file.

    Args:
        input_file (str): The full path to the Python source file.
        variable_name (str): The name of the variable holding the agent object.
        output_file (str): The full path for the output pickle file.
    """
    try:
        output_dir = os.path.dirname(output_file)
        if output_dir and not os.path.isdir(output_dir):
            print(f"Error: The output directory '{output_dir}' does not exist.", file=sys.stderr)
            return

        module_name = os.path.splitext(os.path.basename(input_file))[0]

        spec = importlib.util.spec_from_file_location(module_name, input_file)
        if spec is None or spec.loader is None:
            print(f"Error: Could not import module from {input_file}", file=sys.stderr)
            return

        module = importlib.util.module_from_spec(spec)

        spec.loader.exec_module(module)

        local_agent = getattr(module, variable_name)

        with open(output_file, "wb") as f:
            cloudpickle.dump(local_agent, f)

        print(f"Successfully serialized '{variable_name}' from '{input_file}' to '{output_file}'")

    except FileNotFoundError:
        print(f"Error: The input file '{input_file}' was not found.", file=sys.stderr)
    except AttributeError:
        print(f"Error: The variable '{variable_name}' was not found in '{input_file}'.", file=sys.stderr)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Serialize a dynamically loaded agent from a variable in a specified file."
    )
    parser.add_argument(
        "input_file",
        help="The full path to the Python source file (e.g., 'my_agents/main.py')."
    )
    parser.add_argument(
        "--variable-name",
        default="local_agent",
        help="The name of the agent variable to serialize (default: 'local_agent')."
    )
    parser.add_argument(
        "--output-file",
        default="pickle.pkl",
        help="The full path for the output pickle file (e.g., 'output/agent.pkl'). Default is 'pickle.pkl' in the current directory."
    )

    args = parser.parse_args()

    serialize_agent_from_file(args.input_file, args.variable_name, args.output_file)
