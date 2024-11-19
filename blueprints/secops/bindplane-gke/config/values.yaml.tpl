# This ingress example uses Ingress NGINX and Cert Manager
# for creating Lets Encrypt signed certificates.
#
# - https://kubernetes.github.io/ingress-nginx/deploy/#gce-gke
# - https://cert-manager.io/docs/tutorials/getting-started-with-cert-manager-on-google-kubernetes-engine-using-lets-encrypt-for-ingress-ssl/
#
ingress:
  enable: true
  host: ${hostname}
  class: "gce-internal"
  tls:
    enable: true
    secret: bindplane-tls
  annotations:
    # cert-manager.io/issuer: letsencrypt
    kubernetes.io/ingress.regional-static-ip-name: ${address}

config:
  # Use the secret named "bindplane", which contains
  # the license, username, password, secret_key, and sessions_secret.
  # If you do not want to use a secret, see the comment below and
  # disable this option.
  licenseUseSecret: true

  # Defaults to wss://bindplane.bindplane.svc.cluster.local:3001/v1/opamp,
  # which is the bindplane namespace's bindplane service. This is suitable
  # for connecting agents within the same cluster. We are using ingress
  # so server_url needs to be updated to the ingress host.
  # NOTE: server_url maps to bindplane's network.remoteURL option.
  server_url: https://${hostname}


# Enables mutli account, allowing you to create
# multiple Tenants within the same BindPlane instance.
multiAccount: true

# Fixed number of pods. BindPlane CPU usage is bursty, using
# a pod autoscaler can be tricky. Generally a fixed number
# of pods is recommended.
replicas: 2

resources:
  # Allow cpu bursting by leaving limits.cpu unset
  requests:
    cpu: '1000m'
    memory: '4096Mi'
  limits:
    memory: '4096Mi'

# Node pools must be authenticated to Pub/Sub with one of the following options
# - Pub/Sub scope enabled
# - GKE Service Account with Pub/Sub permissions
# - Service Account key file and the GOOGLE_APPLICATION_CREDENTIALS environment variable set
#   to the path of the key file. You can use extraVolumes, extraVolumeMounts, extraEnv to
#   mount a configMap or secret containing the key file.
eventbus:
  type: 'pubsub'
  pubsub:
    projectid: '${gcp_project_id}'
    topic: 'bindplane'

backend:
  type: postgres
  postgres:
    host: '${postgresql_ip}'
    port: 5432
    database: 'bindplane'
    username: '${postgresql_username}'
    password: '${postgresql_password}'
    # Replicas * max connections should not exceed
    # your Postgres instance's max connections.
    # This option defaults to 100, which is too high
    # for an environment with 7 replicas.
    maxConnections: 20

transform_agent:
  replicas: 2

# Prometheus is deployed and managed by the Helm chart. At scale
# it will require additional resources which can be set here.
prometheus:
  resources:
    requests:
      cpu: '2000m'
      memory: '8192Mi'
    limits:
      memory: '8192Mi'
  storage:
    volumeSize: '120Gi'