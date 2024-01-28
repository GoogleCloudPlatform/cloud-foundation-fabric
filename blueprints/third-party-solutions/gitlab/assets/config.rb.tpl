# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# /etc/gitlab/gitlab.rb

external_url "https://${hostname}"
letsencrypt['enable'] = false
nginx['redirect_http_to_https'] = true

# https://docs.gitlab.com/omnibus/settings/redis.html
gitlab_rails['redis_enable_client'] = false
gitlab_rails['redis_host'] = '${redis.host}'
gitlab_rails['redis_port'] = ${redis.port}
# TODO: use auth
# gitlab_rails['redis_password'] = nil
redis['enable'] = false

# https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server
postgresql['enable'] = false
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'utf8'
gitlab_rails['db_host'] = '${cloudsql.host}'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_password'] = '${cloudsql.password}'

# https://docs.gitlab.com/ee/administration/object_storage.html#google-cloud-storage-gcs
# Consolidated object storage configuration
gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['proxy_download'] = true
gitlab_rails['object_store']['connection'] = {
  'provider'                   => 'Google',
  'google_project'             => '${project_id}',
  'google_application_default' => true
}
# full example using the consolidated form
# https://docs.gitlab.com/ee/administration/object_storage.html#full-example-using-the-consolidated-form-and-amazon-s3
gitlab_rails['object_store']['objects']['artifacts']['bucket'] = '${prefix}-gitlab-artifacts'
gitlab_rails['object_store']['objects']['external_diffs']['bucket'] = '${prefix}-gitlab-mr-diffs'
gitlab_rails['object_store']['objects']['lfs']['bucket'] = '${prefix}-gitlab-lfs'
gitlab_rails['object_store']['objects']['uploads']['bucket'] = '${prefix}-gitlab-uploads'
gitlab_rails['object_store']['objects']['packages']['bucket'] = '${prefix}-gitlab-packages'
gitlab_rails['object_store']['objects']['dependency_proxy']['bucket'] = '${prefix}-gitlab-dependency-proxy'
gitlab_rails['object_store']['objects']['terraform_state']['bucket'] = '${prefix}-gitlab-terraform-state'
gitlab_rails['object_store']['objects']['pages']['bucket'] = '${prefix}-gitlab-pages'

# SAML configuration
# https://docs.gitlab.com/ee/integration/saml.html
%{ if saml != null }
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_external_providers'] = ['saml']
# create new user in case of sign in with SAML provider
gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
# do not force approval from admins for newly created users
gitlab_rails['omniauth_block_auto_created_users'] = false
# automatically link a first-time SAML sign-in with existing GitLab users if their email addresses match
gitlab_rails['omniauth_auto_link_saml_user'] = true
# Force user redirection to SAML
# To bypass the auto sign-in setting, append ?auto_sign_in=false in the sign in URL, for example: https://gitlab.example.com/users/sign_in?auto_sign_in=false.
%{ if saml.forced }
gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
%{ endif }
# SHA1 Fingerprint
gitlab_rails['omniauth_providers'] = [
  {
    name: "saml",
    label: "SAML",
    args: {
      assertion_consumer_service_url: "https://${hostname}/users/auth/saml/callback",
      idp_cert_fingerprint: '${saml.idp_cert_fingerprint}',
      idp_sso_target_url: '${saml.sso_target_url}',
      issuer: "https://${hostname}",
      name_identifier_format: "${saml.name_identifier_format}"
    }
  }
]
%{ endif }


# mail configuration
%{ if mail.sendgrid != null }
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.sendgrid.net"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "apikey"
gitlab_rails['smtp_password'] = "${mail.sendgrid.api_key}"
gitlab_rails['smtp_domain'] = "smtp.sendgrid.net"
gitlab_rails['smtp_authentication'] = "plain"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
# If use Single Sender Verification You must configure from. If not fail
# 550 The from address does not match a verified Sender Identity. Mail cannot be sent until this error is resolved.
# Visit https://sendgrid.com/docs/for-developers/sending-email/sender-identity/ to see the Sender Identity requirements
%{ if try(mail.sendgrid.email_from != null, false) }
gitlab_rails['gitlab_email_from'] = '${mail.sendgrid.email_from}'
%{ endif }
%{ if try(mail.sendgrid.email_reply_to != null, false) }
gitlab_rails['email_reply_to'] = '${mail.sendgrid.email_reply_to}'
%{ endif }
%{ endif }


gitlab_rails['gitlab_shell_ssh_port'] = 2222
# gitlab_sshd['enable'] = true
# gitlab_sshd['listen_address'] = '[::]:2222'

# https://docs.gitlab.com/omnibus/installation/index.html#set-up-the-initial-password
# gitlab_rails['initial_root_password'] = '<my_strong_password>'