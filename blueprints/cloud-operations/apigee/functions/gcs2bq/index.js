/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

 const functions = require("@google-cloud/functions-framework");
 const { Storage } = require('@google-cloud/storage');
 const { BigQuery } = require('@google-cloud/bigquery');
 const bunyan = require('bunyan');
 const schema = require('./schema.json');
 
 const { LoggingBunyan } = require('@google-cloud/logging-bunyan');
 
 const loggingBunyan = new LoggingBunyan();
 
 const logger = bunyan.createLogger({
   name: 'gcs2bq',
   streams: [
     { stream: process.stdout, level: 'info' },
     loggingBunyan.stream('info')
   ],
 });
 
 const DATASET = process.env.DATASET
 const TABLE = process.env.TABLE
 const LOCATION = process.env.LOCATION
 
 async function loadCSVFromGCS(datasetId, tableId, timePartition, bucket, filename) {
   const metadata = {
     sourceFormat: 'CSV',
     skipLeadingRows: 1,     
     maxBadRecords: 1000,
     schema: {
       fields: schema
     },
    location: LOCATION
   };
 
   logger.info(`Trying to load ${bucket}/${filename} in ${timePartition} time partition of table ${tableId}...`);
   const bigquery = new BigQuery();
   const storage = new Storage();
   const [job] = await bigquery
     .dataset(datasetId)
     .table(`${tableId}\$${timePartition}`)
     .load(storage.bucket(bucket).file(filename), metadata);
   logger.info(`Job ${job.id} completed.`);
   const errors = job.status.errors;
   if (errors && errors.length > 0) {
     logger.info('Errors occurred:' + JSON.stringify(errors));
     throw new Error('File could not be loaded in time partition');
   }
 }
 
 functions.cloudEvent("gcs2bq", async (cloudEvent) => {
 
   const data = JSON.parse(Buffer.from(cloudEvent.data.message.data, 'base64').toString());
   logger.info('Notification received');
   logger.info(data);
   const pattern = /([^/]+\/)?[0-9]{14}\-[0-9a-z]{8}\-[0-9a-z]{4}\-[0-9a-z]{4}\-[0-9a-z]{4}\-[0-9a-z]{12}\-api\-from\-([0-9]{8})0000\-to\-([0-9]{8})0000\/result\-[0-9]+\.csv\.gz/
   const result = data.name.match(pattern);
   const timePartition = result[2];

   await loadCSVFromGCS(DATASET, TABLE, timePartition, data.bucket, data.name)
 
 });
