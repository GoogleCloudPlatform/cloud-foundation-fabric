# Copyright 2023 Google LLC
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

import apache_beam as beam
from apache_beam.io import ReadFromText, Read, WriteToBigQuery, BigQueryDisposition
from apache_beam.options.pipeline_options import PipelineOptions, SetupOptions
from apache_beam.io.filesystems import FileSystems
import json
import argparse


class ParseRow(beam.DoFn):
    """
    Splits a given csv row by a separator, validates fields and returns a dict
    structure compatible with the BigQuery transform
    """

    def process(self, element: str, table_fields: list, delimiter: str):
        split_row = element.split(delimiter)
        parsed_row = {}

        for i, field in enumerate(table_fields['BigQuery Schema']):
            parsed_row[field['name']] = split_row[i]

        yield parsed_row

def run(argv=None, save_main_session=True):
    parser = argparse.ArgumentParser()
    parser.add_argument('--csv_file',
                        type=str,
                        required=True,
                        help='Path to the CSV file')
    parser.add_argument('--json_schema',
                        type=str,
                        required=True,
                        help='Path to the JSON schema')
    parser.add_argument('--output_table',
                        type=str,
                        required=True,
                        help='BigQuery path for the output table')

    args, pipeline_args = parser.parse_known_args(argv)
    pipeline_options = PipelineOptions(pipeline_args)
    pipeline_options.view_as(
        SetupOptions).save_main_session = save_main_session

    with beam.Pipeline(options=pipeline_options) as p:

        def get_table_schema(table_path, table_schema):
            return {'fields': table_schema['BigQuery Schema']}

        csv_input = p | 'Read CSV' >> ReadFromText(args.csv_file)
        schema_input = p | 'Load Schema' >> beam.Create(
            json.loads(FileSystems.open(args.json_schema).read()))

        table_fields = beam.pvalue.AsDict(schema_input)
        parsed = csv_input | 'Parse and validate rows' >> beam.ParDo(
            ParseRow(), table_fields, ',')

        parsed | 'Write to BigQuery' >> WriteToBigQuery(
            args.output_table,
            schema=get_table_schema,
            create_disposition=BigQueryDisposition.CREATE_IF_NEEDED,
            write_disposition=BigQueryDisposition.WRITE_TRUNCATE,
            schema_side_inputs=(table_fields, ))

if __name__ == "__main__":
    run()
