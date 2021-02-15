# Copyright 2021 Google LLC
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

"""Dataflow pipeline. Reads a CSV file and writes to a BQ table adding a timestamp.
"""


import argparse
import logging
import re

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions


class DataIngestion:
  """A helper class which contains the logic to translate the file into
  a format BigQuery will accept."""

  def parse_method(self, string_input):
    """Translate CSV row to dictionary.
    Args:
        string_input: A comma separated list of values in the form of
            name,surname
            Example string_input: lorenzo,caggioni
    Returns:
        A dict mapping BigQuery column names as keys
        example output:
        {
            'name': 'mario',
            'surname': 'rossi',
            'age': 30
        }
     """
    # Strip out carriage return, newline and quote characters.
    values = re.split(",", re.sub('\r\n', '', re.sub('"', '',
                                                     string_input)))
    row = dict(
        zip(('name', 'surname', 'age'),
            values))
    return row


class InjectTimestamp(beam.DoFn):
  """A class which add a timestamp for each row.
  Args:
      element: A dictionary mapping BigQuery column names
          Example:
          {
              'name': 'mario',
              'surname': 'rossi',
              'age': 30
          }
      Returns:
         The input dictionary with a timestamp value added
         Example:
          {
              'name': 'mario',
              'surname': 'rossi',
              'age': 30
              '_TIMESTAMP': 1545730073
          }
  """

  def process(self, element):
    import time
    element['_TIMESTAMP'] = int(time.mktime(time.gmtime()))
    return [element]


def run(argv=None):
  """The main function which creates the pipeline and runs it."""

  parser = argparse.ArgumentParser()

  parser.add_argument(
      '--input',
      dest='input',
      required=False,
      help='Input file to read. This can be a local file or '
      'a file in a Google Storage Bucket.')

  parser.add_argument(
      '--output',
      dest='output',
      required=False,
      help='Output BQ table to write results to.')

  # Parse arguments from the command line.
  known_args, pipeline_args = parser.parse_known_args(argv)

  # DataIngestion is a class we built in this script to hold the logic for
  # transforming the file into a BigQuery table.
  data_ingestion = DataIngestion()

  # Initiate the pipeline using the pipeline arguments
  p = beam.Pipeline(options=PipelineOptions(pipeline_args))

  (p
   # Read the file. This is the source of the pipeline.
   | 'Read from a File' >> beam.io.ReadFromText(known_args.input)
   # Translates CSV row to a dictionary object consumable by BigQuery.
   | 'String To BigQuery Row' >>
   beam.Map(lambda s: data_ingestion.parse_method(s))
   # Add the timestamp on each row
   | 'Inject Timestamp - ' >> beam.ParDo(InjectTimestamp())
   # Write data to Bigquery
   | 'Write to BigQuery' >> beam.io.Write(
       beam.io.BigQuerySink(
           # BigQuery table name.
           known_args.output,
           # Bigquery table schema
           schema='name:STRING,surname:STRING,age:NUMERIC,_TIMESTAMP:TIMESTAMP',
           # Creates the table in BigQuery if it does not yet exist.
           create_disposition=beam.io.BigQueryDisposition.CREATE_NEVER,
           # Deletes all data in the BigQuery table before writing.
           write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE)))
  p.run().wait_until_finish()


if __name__ == '__main__':
  logging.getLogger().setLevel(logging.INFO)
  run()
