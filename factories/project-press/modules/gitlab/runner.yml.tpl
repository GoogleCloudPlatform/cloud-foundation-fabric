imagePullPolicy: IfNotPresent
gitlabUrl: "${gitlab_server}"
unregisterRunners: true
terminationGracePeriodSeconds: 3600
concurrent: 10
checkInterval: 21
rbac:
  create: false
  serviceAccountName: "${service_account}"
  resources: ["pods", "pods/exec", "secrets"]
  verbs: ["get", "list", "watch", "create", "patch", "delete"]
  clusterWideAccess: false
metrics:
  enabled: true
runners:
  image: gitlab/gitlab-runner:alpine
  privileged: false
  secret: "${secret}"
  namespace: "${namespace}"
  pollTimeout: 180
  outputLimit: 4096
  cache: {}
  builds: {}
  services: {}
  helpers: {}
  serviceAccountName: "${service_account}"
  cloneUrl: "${gitlab_server}"
  tags: "cloud,${tag},${project}"
  runUntagged: false
  locked: true
  builds:
    cpuRequests: 250m
    memoryRequests: 256Mi
  services:
    cpuRequests: 250m
    memoryRequests: 256Mi
  helpers:
    cpuRequests: 250m
    memoryRequests: 256Mi
resources: {}
affinity: {}
nodeSelector: {}
tolerations: []
hostAliases: []
podAnnotations: {}