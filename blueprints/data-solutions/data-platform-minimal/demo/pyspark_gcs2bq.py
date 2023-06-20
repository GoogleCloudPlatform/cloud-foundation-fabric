#!/usr/bin/env python

# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

""" Sample pyspark script to read data CSV data from Cloud Storage and 
import into BigQuery. The script runs on Cloud Dataproc Serverless.

Note this file is not intended to be run directly, but run inside a PySpark
environment.
"""
import sys

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import StructType,TimestampType, StringType, IntegerType

# Create a Spark session
spark = SparkSession.builder \
.appName("Read CSV from GCS and Write to BigQuery") \
.getOrCreate()

# Read parameters
csv = spark.sparkContext.parallelize([sys.argv[1]]).first()
dataset_table = spark.sparkContext.parallelize([sys.argv[2]]).first()
tmp_gcs = spark.sparkContext.parallelize([sys.argv[3]]).first()

spark.conf.set('temporaryGcsBucket', tmp_gcs)

schema = StructType() \
      .add("id",IntegerType(),True) \
      .add("name",StringType(),True) \
      .add("surname",StringType(),True) \
      .add("timestamp",TimestampType(),True)

data = spark.read.format("csv") \
      .schema(schema) \
      .load(csv)

# add lineage metadata: input filename and loading ts
data = data.select('*',
                (F.input_file_name()).alias('input_filename'),
                (F.current_timestamp()).alias('load_ts') 
                )

# Saving the data to BigQuery
data.write.format('bigquery') \
.option('table', dataset_table) \
.mode('append') \
.save()