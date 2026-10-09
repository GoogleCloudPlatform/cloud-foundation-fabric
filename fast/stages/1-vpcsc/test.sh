#!/usr/bin/env bash

# Bulletproof helper script to inject missing Service Usage roles for Stage 1 service accounts

python3 -c '
import os

paths = [
    "../0-org-setup/datasets/classic/projects/core/iac-0.yaml",
    "fast/stages/0-org-setup/datasets/classic/projects/core/iac-0.yaml"
]

path = None
for p in paths:
    if os.path.exists(p):
        path = p
        break

if not path:
    print("ERROR: iac-0.yaml could not be found.")
    exit(1)

with open(path, "r") as f:
    lines = f.readlines()

# Check if already added
content_str = "".join(lines)
if "iac-vpcsc-rw" in content_str:
    print("SUCCESS: iac-vpcsc-rw is already present in your iac-0.yaml!")
    exit(0)

new_lines = []
inserted = False

for line in lines:
    new_lines.append(line)
    if "iam_by_principals:" in line and not inserted:
        # Get indentation of the next line (or default to 2 spaces)
        new_lines.append("  $iam_principals:service_accounts/iac-0/iac-vpcsc-rw:\n")
        new_lines.append("    - roles/serviceusage.serviceUsageConsumer\n")
        new_lines.append("  $iam_principals:service_accounts/iac-0/iac-vpcsc-ro:\n")
        new_lines.append("    - roles/serviceusage.serviceUsageConsumer\n")
        inserted = True

if inserted:
    with open(path, "w") as f:
        f.writelines(new_lines)
    print("SUCCESS: iac-0.yaml was successfully updated directly in your workspace!")
else:
    print("ERROR: Could not find the iam_by_principals: block inside iac-0.yaml.")
'
