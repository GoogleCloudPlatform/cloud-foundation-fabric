
```bash
gcloud beta service-directory services create app3 \
  --location europe-west1 \
  --namespace dns-sd-test
gcloud beta service-directory endpoints create vm1 \
  --service app3 \
  --location europe-west1 \
  --namespace dns-sd-test \
  --address 127.0.0.6 \
  -- port 80

dig app3.svc.example.org +short
127.0.0.6

dig _app3._tcp.app3.svc.example.org SRV +short
10 10 80 vm1.app3.svc.example.org.
```

```bash
gcloud beta service-directory endpoints delete vm1 \
  --service app3 \
  --location europe-west1 \
  --namespace dns-sd-test
gcloud beta service-directory endpoints create vm3 \
  --service app1 \
  --location europe-west1 \
  --namespace dns-sd-test \
  --address 127.0.0.7 \
  --port 80
```