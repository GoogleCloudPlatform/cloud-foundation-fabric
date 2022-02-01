The cluster/ directory contains configs that apply to entire clusters, rather than to namespaces. By default, any config in the cluster/ directory applies to every cluster enrolled in Config Sync. You can limit which clusters a config can affect by using a ClusterSelector.

Doc ref: https://cloud.google.com/anthos-config-management/docs/concepts/hierarchical-repo#cluster