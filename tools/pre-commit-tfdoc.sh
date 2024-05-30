#!/bin/bash

set -ev

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

files=("$@")
declare -A directories

for file in "${files[@]}"; do
	dir=$(dirname "${file}")
	if [ -f "${dir}/README.md" ] && [ -f "${dir}/main.tf" ]; then
		directories["${dir}"]=1
	fi
done

for dir in "${!directories[@]}"; do # iterate over keys in directories
	echo python "${SCRIPT_DIR}/tfdoc.py" "${dir}"
	python "${SCRIPT_DIR}/tfdoc.py" "${dir}"
done
