// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

const functions = require("@google-cloud/functions-framework");
const superagent = require("superagent");
const { LoggingBunyan } = require("@google-cloud/logging-bunyan");
const bunyan = require("bunyan");
const { GoogleAuth } = require("google-auth-library");

const loggingBunyan = new LoggingBunyan();
const logger = bunyan.createLogger({
  name: "analyticsExport",
  streams: [
    { stream: process.stdout, level: "info" },
    loggingBunyan.stream("info"),
  ],
});

const ORGANIZATION = process.env.ORGANIZATION;
const ENVIRONMENTS = process.env.ENVIRONMENTS.split(',');
const DATASTORE = process.env.DATASTORE;

const MANAGEMENT_API_URL = "https://apigee.googleapis.com/v1";

function formatDate(date) {
  var d = new Date(date),
    month = "" + (d.getMonth() + 1),
    day = "" + d.getDate(),
    year = d.getFullYear();

  if (month.length < 2) month = "0" + month;
  if (day.length < 2) day = "0" + day;

  return [year, month, day].join("-");
}

async function getAccessToken() {
  logger.info("Requesting access token...");
  const auth = new GoogleAuth();
  const token = await auth.getAccessToken();
  logger.info("Got access token ");
  return token;
}

async function scheduleAnalyticsExport(org, env, token, startDate, endDate) {
  logger.info(
    `Sending request for an analytics export from  ${startDate} to ${endDate} for environment ${env}`
  );
  try {
    const response = await superagent
      .post(
        `${MANAGEMENT_API_URL}/organizations/${org}/environments/${env}/analytics/exports`
      )
      .send({
        name: `Analytics from ${startDate} to ${endDate}`,
        description: `Analytics from ${startDate} to ${endDate}`,
        dateRange: {
          start: startDate,
          end: endDate,
        },
        outputFormat: "csv",
        csvDelimiter: ",",
        datastoreName: DATASTORE,
      })
      .set('Authorization', `Bearer ${token}`)
      .accept('json');
    logger.info('Analytics export scheduled');
    return response;
  } catch (error) {
    logger.error('Error scheduling analytics export');
    logger.error(error);
    throw error;
  }
}

functions.cloudEvent("export", async (cloudEvent) => {
  const today = new Date();
  const endDate = formatDate(today);
  const yesterday = new Date(today.setDate(today.getDate() - 1));
  const startDate = formatDate(yesterday);
  const token = await getAccessToken();
  try {
    for(let i = 0; i < ENVIRONMENTS.length; i++) {
      const env = ENVIRONMENTS[i];
      const response = await scheduleAnalyticsExport(ORGANIZATION, env, token, startDate, endDate);
      logger.error('Export scheduled: ' + response.body.self);
    }
  } catch (error) {
    logger.error('Analytics exports was not scheduled');
    logger.error(error);
  }
});
