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

import argparse
import os
import sys

try:
  import vertexai
  from vertexai.generative_models import GenerativeModel
except ImportError:
  print("Error: google-cloud-aiplatform is not installed.", file=sys.stderr)
  print("Please install it via: pip install google-cloud-aiplatform",
        file=sys.stderr)
  sys.exit(1)


def main():
  parser = argparse.ArgumentParser(
      description="Run Gemini PR Review via Vertex AI")
  parser.add_argument("--project", required=True, help="GCP Project ID")
  parser.add_argument("--location", default="us-central1", help="GCP Region")
  parser.add_argument("--model", default="gemini-3.1-pro-preview",
                      help="Gemini model name")
  parser.add_argument("--diff-file", required=True,
                      help="Path to the PR diff file")
  args = parser.parse_args()

  # Read local repository guidelines
  repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
  gemini_md_path = os.path.join(repo_root, "GEMINI.md")
  contributing_md_path = os.path.join(repo_root, "CONTRIBUTING.md")

  guidelines = ""
  if os.path.exists(gemini_md_path):
    with open(gemini_md_path, "r") as f:
      guidelines += f"\n--- GEMINI.md ---\n{f.read()}"
  if os.path.exists(contributing_md_path):
    with open(contributing_md_path, "r") as f:
      guidelines += f"\n--- CONTRIBUTING.md ---\n{f.read()}"

  # Read diff
  try:
    with open(args.diff_file, "r") as f:
      diff_content = f.read()
  except Exception as e:
    print(f"Error reading diff file: {e}", file=sys.stderr)
    sys.exit(1)

  if not diff_content.strip():
    print("No diff content found. Skipping review.")
    return

  # Initialize Vertex AI
  try:
    vertexai.init(project=args.project, location=args.location)
  except Exception as e:
    print(f"Error initializing Vertex AI: {e}", file=sys.stderr)
    sys.exit(1)

  # Construct the System Instruction
  system_instruction = f"""You are an expert Google Cloud and Terraform code reviewer.
Your task is to review a Pull Request diff for the Cloud Foundation Fabric repository.

You MUST strictly enforce the repository's architecture, conventions, and style guidelines.
Here are the repository guidelines you must follow:
{guidelines}

Review the provided git diff. Provide a concise, constructive review.
- Highlight any violations of the guidelines (e.g., naming conventions, missing context support, incorrect IAM patterns, missing tests).
- Suggest specific code improvements.
- If the code looks good and follows all guidelines, state that clearly.
- Format your output in Markdown so it can be posted directly as a GitHub PR comment.
- CRITICAL: Keep your entire response concise. The GitHub PR comment size limit is 65536 characters. Your response MUST be well under this limit (e.g., maximum 50000 characters). Focus only on the most important feedback.
"""

  model = GenerativeModel(
      model_name=args.model,
      system_instruction=system_instruction,
  )

  prompt = f"Here is the PR diff to review:\n```diff\n{diff_content}\n```"

  try:
    # Using a low temperature for a more analytical/deterministic review
    response = model.generate_content(prompt,
                                      generation_config={"temperature": 0.2})
    print(response.text)
  except Exception as e:
    print(f"Error calling Vertex AI: {e}", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
  main()
