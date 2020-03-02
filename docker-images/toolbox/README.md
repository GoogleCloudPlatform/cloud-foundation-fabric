
# ToolBox docker container
### The folowing tools are included:
- wget
- curl
- openssh
- unzip
- python
- netcat
- ipset
- traceroute
- dnsutils
- ping
- telnet

### Docker compose example
```yaml
version: "3"
services:
  vpn:
    image: gcr.io/pso-cft-fabric/toolbox:latest
    networks:
      default:
        ipv4_address: 192.168.0.5
    cap_add:
      - NET_ADMIN
    privileged: true

```

### Build
```bash
gcloud builds submit . --config=cloudbuild.yaml
```
