[program:netmontool]
directory=/opt/app/source
command=/opt/app/env/bin/python3 /opt/app/source/main.py --project ${mon_project_id} --agent ${identifier} %{ for ip, port in target_endpoints ~} --endpoint "${ip}" ${port} %{ endfor } --timeout ${timeout} --interval ${interval}
autostart=true
autorestart=true
user=net-mon-agent
# Environment variables ensure that the application runs inside of the configured virtualenv.
environment=VIRTUAL_ENV="/opt/app/env",PATH="/opt/app/env/bin",HOME="/home/net-mon-agent",USER="net-mon-agent"
stdout_logfile=syslog
stderr_logfile=syslog