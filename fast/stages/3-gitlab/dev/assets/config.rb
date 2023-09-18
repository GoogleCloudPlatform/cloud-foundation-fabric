# /etc/gitlab/gitlab.rb

# https://docs.gitlab.com/omnibus/settings/redis.html
gitlab_rails['redis_enable_client'] = false
gitlab_rails['redis_host'] = '${redis.host}'
gitlab_rails['redis_port'] = ${redis.port}
# TODO: use auth
# gitlab_rails['redis_password'] = nil
redis['enable'] = false

# https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'utf8'
gitlab_rails['db_host'] = '${cloudsql.host}'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_username'] = '${cloudsql.username}'
gitlab_rails['db_password'] = '${cloudsql.password}'
postgresql['enable'] = false

# https://docs.gitlab.com/ee/administration/object_storage.html#google-cloud-storage-gcs
gitlab_rails['object_store']['connection'] = {
  'provider'                   => 'Google',
  'google_project'             => '${project_id}',
  'google_application_default' => true
}

gitlab_rails['gitlab_shell_ssh_port'] = 2222
# gitlab_sshd['enable'] = true
# gitlab_sshd['listen_address'] = '[::]:2222'

# https://docs.gitlab.com/omnibus/installation/index.html#set-up-the-initial-password
# gitlab_rails['initial_root_password'] = '<my_strong_password>'