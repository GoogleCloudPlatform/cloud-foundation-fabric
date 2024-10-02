#!/bin/bash
# Copyright 2018 Google LLC
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

# Configure Git to use gcloud.sh as the credential helper for Secure Source Manager
git config --global credential.'https://*.*.sourcemanager.dev'.helper gcloud.sh

# Copy the .gitignore file from the parent directory
cp ../../../.gitignore .

# Set the target directory from the first argument ($1)
target_dir="$1"

# Change to the target directory
cd "$target_dir" || exit 1  # Exit with an error if cd fails

# Initialize a new Git repository in the current directory
git init

# Stage all files in the current directory and its subdirectories
git add .

# Create a new commit with a descriptive message
git commit -m "Initial push from fast cli"

# Add the remote repository URL provided as the second argument ($2)
git remote add origin "$2"

# Set the default branch to 'main' if the third argument ($3) is not provided
branch="${3:-main}"

# Push the changes to the specified branch on the remote repository
git push -u origin "$branch"