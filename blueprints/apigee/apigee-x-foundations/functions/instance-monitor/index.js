/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const functions = require("@google-cloud/functions-framework");
const monitoring = require("@google-cloud/monitoring");
const logging = require("@google-cloud/logging");
const { LoggingBunyan } = require("@google-cloud/logging-bunyan");
const bunyan = require("bunyan");

const loggingBunyan = new LoggingBunyan();
const logger = bunyan.createLogger({
  name: "instance-monitor",
  streams: [{ stream: process.stdout, level: "info" }, loggingBunyan.stream("info")],
});

const SEVERITY_THRESHOLD = logging.Severity.warning;

const METRIC_DESCRIPTION = "Apigee instance health.";
const METRIC_DISPLAY_NAME = "Apigee instance health.";
const METRIC_TYPE = "custom.googleapis.com/apigee/instance_health";
const METRIC_KIND = "GAUGE";
const METRIC_VALUE_TYPE = "BOOL";
const METRIC_UNIT = "1";
const METRIC_LABELS = [
  {
    key: "org",
    valueType: "STRING",
    description: "The name of the apigee organization.",
  },
  {
    key: "instance_id",
    valueType: "STRING",
    description: "The ID of the apigee instance.",
  }
];
const RESOURCE_TYPE = "global";
const METRIC_DESCRIPTOR = {
  description: METRIC_DESCRIPTION,
  displayName: METRIC_DISPLAY_NAME,
  type: METRIC_TYPE,
  metricKind: METRIC_KIND,
  valueType: METRIC_VALUE_TYPE,
  unit: METRIC_UNIT,
  labels: METRIC_LABELS,
};

const client = new monitoring.MetricServiceClient();

async function createMetricDescriptor(projectId, metricDescriptor) {
  const request = {
    name: client.projectPath(projectId),
    metricDescriptor: metricDescriptor,
  };
  return await client.createMetricDescriptor(request);
}

async function getMetricDescriptor(projectId, metricType) {
  const request = {
    name: client.projectMetricDescriptorPath(projectId, metricType),
  };
  return await client.getMetricDescriptor(request);
}

async function writeTimeSeriesData(projectId, metricType, resourceType, value, metricLabels) {
  const dataPoint = {
    interval: {
      endTime: {
        seconds: Date.now() / 1000,
      },
    },
    value: {
      boolValue: value,
    },
  };

  const timeSeriesData = {
    metric: {
      type: metricType,
      labels: metricLabels,
    },
    resource: {
      type: resourceType,
      labels: {
        project_id: projectId,
      },
    },
    points: [dataPoint],
  };

  const request = {
    name: client.projectPath(projectId),
    timeSeries: [timeSeriesData],
  };

  return await client.createTimeSeries(request);
}

async function processEvent(cloudEvent) {
  const [, projectId, instanceId] = /^organizations\/(.+)\/instances\/(.+)$/g.exec(cloudEvent.resourcename);
  const severity = logging.Severity[cloudEvent.data.severity.toLowerCase()];
  const value = severity >= SEVERITY_THRESHOLD;
  if (!value) {
    logger.error(`Instance ${instanceId} in ${organization} is down`);
  }
  try {
    logger.debug("Checking if metric exists...");
    const result = await getMetricDescriptor(projectId, METRIC_TYPE);
    logger.debug("Metric already exists", result);
  } catch (error) {
    logger.debug("Metric does not exist. Creating it...");
    const result = await createMetricDescriptor(projectId, METRIC_DESCRIPTOR);
    logger.debug("Metric created", result);
  }
  logger.debug("Writing data point...");
  await writeTimeSeriesData(projectId, METRIC_TYPE, RESOURCE_TYPE, value, {
    org: projectId,
    instance_id: instanceId,
  });
}

functions.cloudEvent("writeMetric", async cloudEvent => {
  logger.debug("Notification received. Let's process it...");
  processEvent(cloudEvent);
  logger.debug("Notification processed.");
});
