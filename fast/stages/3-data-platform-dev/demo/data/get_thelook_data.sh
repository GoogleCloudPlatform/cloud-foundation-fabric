#!/bin/bash
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Script to export data from BigQuery public dataset to GCS bucket
# Usage: ./export_bigquery_data.sh gs://your-bucket-name

set -e # Exit on error

# Check if argument is provided
if [ $# -eq 0 ]; then
	echo "Error: No GCS bucket provided"
	echo "Usage: $0 gs://your-bucket-name"
	exit 1
fi

GCS_BUCKET=$1

# Validate that the bucket starts with gs://
if [[ ! "$GCS_BUCKET" =~ ^gs:// ]]; then
	echo "Error: GCS bucket must start with gs://"
	echo "Example: gs://your-bucket-name"
	exit 1
fi

# Check if bq command is available
if ! command -v bq &>/dev/null; then
	echo "Error: bq command not found. Please install Google Cloud SDK."
	exit 1
fi

# Remove trailing slash if present
GCS_BUCKET=${GCS_BUCKET%/}

# Source project and dataset
SOURCE_PROJECT="bigquery-public-data"
SOURCE_DATASET="thelook_ecommerce"

# Tables to export
TABLES=("users" "orders" "order_items" "products")

echo "Starting export from ${SOURCE_PROJECT}.${SOURCE_DATASET} to $GCS_BUCKET"
echo "================================================"

# Export each table
for table in "${TABLES[@]}"; do
	echo -n "Exporting $table..."

	# Create destination path
	DESTINATION="${GCS_BUCKET}/data/${table}/${table}*.csv"

	# Execute bq extract command
	if bq extract \
		--destination_format CSV \
		--field_delimiter=',' \
		--print_header=true \
		"bigquery-public-data:thelook_ecommerce.${table}" \
		"${DESTINATION}"; then
		echo " SUCCESS"
	else
		echo " FAILED"
		echo "Error: Failed to export $table"
		exit 1
	fi
done

echo "================================================"
echo "All tables exported successfully!"
echo ""
echo "Exported tables:"
for table in "${TABLES[@]}"; do
	echo "  - ${GCS_BUCKET}/data/${table}/"
done
