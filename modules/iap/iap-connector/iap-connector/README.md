# IAP connector

IAP connector helm chart deploys an Ambassador proxy on a Google Kubernetes Engine Cluster which then can be used to route traffic secured by Cloud IAP to your applications running on-prem or in other cloud providers.

## Introduction

This chart bootstraps a configurable number of [Ambassador](https://www.getambassador.io) deployments and gke ingresses on a [gke](https://cloud.google.com/kubernetes-engine/) cluster to route traffic to your backend applications running outside of GCP using the [Helm](https://helm.sh) package manager.

## Prerequisites
- gke cluster (tested with version >= 1.13.10-gke.0)

## Installing the Chart

To install the chart with the release name `my-release` and values file `values_example.yaml` from the helm folder with Helm:

```console
$ helm install --name my-release ./iap-connector -f values_example.yaml
```

To install it with kubectl:

```console
$ helm template --name my-release ./iap-connector -f values_example.yaml | kubectl apply -f -
```


## Uninstalling the Chart

To delete `my-release` deployment with helm:

```console
$ helm delete --purge my-release
```

or with Kubectl

```console
$ helm template --name my-release ./iap-connector -f values_example.yaml | kubectl delete -f -
```

## Configuration

The following tables lists the configurable parameters of the Ambassador chart and their default values.

| Parameter                          | Description                                                                     | Default                           |
| ---------------------------------- | ------------------------------------------------------------------------------- |----------- |
| `ambassadorInstances`              | list of ambassador deployment instances                           |                      |
| `ambassadorInstances.ambassadorID`              | ID to assign to ambassador deployment instance                           | `ambassador-1`                            |
| `ambassadorInstances.replicaCount`            | Number of ambassador replicas for the deployment                              | `3`                            |
| `ambassadorInstances.resources`                | Set resource requests and limits                                      | `{}`                       |
| `ambassadorInstances.image.pullPolicy`                 | Ambassador image pull policy                                                    | `IfNotPresent`                    |
| `ambassadorInstances.image.repository`                 | Ambassador image                                                                | `quay.io/datawire/ambassador`     |
| `ambassadorInstances.image.tag`                        | Ambassador image tag                                                            | `0.39.0`                          |
| `ambassadorInstances.autoscaling.enabled`              | If true, creates Horizontal Pod Autoscaler                                      | `false`                           |
| `ambassadorInstances.autoscaling.minReplica`           | If autoscaling enabled, this field sets minimum replica count                   | `1`                               |
| `ambassadorInstances.autoscaling.maxReplica`           | If autoscaling enabled, this field sets maximum replica count                   |                                |
| `ambassadorInstances.autoscaling.metrics`              | If autoscaling enabled, configure hpa metrics    
| `ingresses`         | List of gke ingresses to create                                | `[]`   |
| `ingresses.name`         | name of gke ingress                               | `""`    |
| `ingresses.externalIpName`         | external ip name allocated for the ingress                                | `""`  | 
| `ingresses.certs`         | list of GCP certificate names  to use (15 certs max per ingress)        | ``    |
| `ingresses.enable_container_native_lb`         | If true use GCP container native loadbalancing                                | `[]`   |
| `ingresses.routing`         | list of routes(each route corresponds to a backend service in gke.)                               | `[]`    |
| `ingresses.routing.name`         | name of the route                               | `""`   |
| `ingresses.routing.ambassadorID`         | which ambassador deployment ID to handle the routing                              | ``    |
| `ingresses.routing.optional_configurations`         | [optional ambassador configuration](https://www.getambassador.io/reference/mappings/#additional-attributes) to assign to that backend service                              | `[]`   |
| `ingresses.routing.mapping`         | Ambassador routing rules for a backend service                               | ``                           |
| `serviceAccount.create`            | If `true`, create a new service account for ambassador                                        | `true`                            |
| `serviceAccount.name`              | Service account to be used                                                      | `ambassador`                      |

**NOTE:** Make sure to create a new ingress whenever you want to use more than 15 certificates associated with that ingress. GCP loadbalancing can support up to 15 certificate. see [here](https://cloud.google.com/load-balancing/docs/ssl-certificates) for more information. 


### Updating the chart

To Upgrade the helm chart with new values from `values_example.yaml` file with helm:

```console
$ helm upgrade --install --wait my-release -f values_example.yaml ./iap-connector
```

with kubectl

```console
$ helm template --name my-release ./iap-connector -f values_example.yaml | kubectl apply -f -
```