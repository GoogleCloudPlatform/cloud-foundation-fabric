import yaml
from google.api import metric_pb2 as ga_metric
from google.cloud import monitoring_v3

def create_metrics(monitoring_project):
  '''
    Creates all Cloud Monitoring custom metrics based on the metric.yaml file

      Parameters:
        None

      Returns:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions
        limits_dict (dictionary of dictionary of string: int): limits_dict[metric_name]: dict[network_name] = limit_value
  '''
  client = monitoring_v3.MetricServiceClient()
  existing_metrics = []
  for desc in client.list_metric_descriptors(name=monitoring_project):
    existing_metrics.append(desc.type)
  limits_dict = {}

  with open("metrics.yaml", 'r') as stream:
    try:
      metrics_dict = yaml.safe_load(stream)

      for metric_list in metrics_dict.values():
        for metric in metric_list.values():
          for sub_metric_key, sub_metric in metric.items():
            metric_link = f"custom.googleapis.com/{sub_metric['name']}"
            # If the metric doesn't exist yet, then we create it
            if metric_link not in existing_metrics:
              create_metric(sub_metric["name"], sub_metric["description"], monitoring_project)
            # Parse limits (both default values and network specific ones)
            if sub_metric_key == "limit":
              limits_dict_for_metric = {}
              for network_link, limit_value in sub_metric["values"].items():
                limits_dict_for_metric[network_link] = limit_value
              limits_dict[sub_metric["name"]] = limits_dict_for_metric

      return metrics_dict, limits_dict
    except yaml.YAMLError as exc:
      print(exc)


def create_metric(metric_name, description, monitoring_project):
  '''
    Creates a Cloud Monitoring metric based on the parameter given if the metric is not already existing

      Parameters:
        metric_name (string): Name of the metric to be created
        description (string): Description of the metric to be created

      Returns:
        None
  '''
  client = monitoring_v3.MetricServiceClient()

  descriptor = ga_metric.MetricDescriptor()
  descriptor.type = f"custom.googleapis.com/{metric_name}"
  descriptor.metric_kind = ga_metric.MetricDescriptor.MetricKind.GAUGE
  descriptor.value_type = ga_metric.MetricDescriptor.ValueType.DOUBLE
  descriptor.description = description
  descriptor = client.create_metric_descriptor(name=monitoring_project,
                                               metric_descriptor=descriptor)
  print("Created {}.".format(descriptor.name))

