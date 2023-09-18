# Gitlab notes

## Open points

- Configure as FAST stage 3
- Integrations
  - Identity (SAML?)
  - Email
- ILB / MIG
- Runners
- Check object store, use GCS wherever possible
- Cloud SQL HA
- Memorystore HA?
- WIF
- DR

## Reference

- [Reference architecture up to 1k users](https://docs.gitlab.com/ee/administration/reference_architectures/1k_users.html)
- [`/etc/gitlab/gitlab.rb` template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)
- [`/etc/gitlab/gitlab.rb` default options](https://docs.gitlab.com/ee/administration/package_information/defaults.html)

## Installation

- [Docker image](https://docs.gitlab.com/ee/install/docker.html)

## Managed services

- [Object storage](https://docs.gitlab.com/ee/administration/object_storage.html)
- [PostgreSQL service](https://docs.gitlab.com/ee/administration/postgresql/external.html)
- [Redis](https://docs.gitlab.com/ee/administration/redis/replication_and_failover_external.html)

# Email

- [Gmail/Workspace](https://docs.gitlab.com/ee/administration/incoming_email.html#gmail)

# Networking and scalability

- [Load balancer](https://docs.gitlab.com/ee/administration/load_balancer.html)

## Identity

- [OpenID Connect OmniAuth](https://docs.gitlab.com/ee/administration/auth/oidc.html#configure-google)
- [Google Secure LDAP](https://docs.gitlab.com/ee/administration/auth/ldap/google_secure_ldap.html)

## HA

- [High Availability](http://ubimol.it/12.0/ee/administration/high_availability/README.html)

## Setup

```bash
psql -h 10.127.0.3 --user sqlserver -d template1 -c "create database gitlabhq_production"
```

## Ludo's config

```hcl
billing_account_id = "0189FA-E139FD-136A58"
gitlab_config = {
  hostname = "gitlab.int.qix.it"
}
prefix      = "tf-playground-svpc"
root_node   = "folders/210938489642"
subnet_name = "gce"
```
