==== request start ====
uri: <https://compute.googleapis.com/batch/compute/v1>
method: POST
== headers start ==
b'authorization': --- Token Redacted ---
b'content-length': b'466'
b'content-type': b'multipart/mixed; boundary="===============2279194272988243142=="'
b'user-agent': b'google-cloud-sdk gcloud/409.0.0 command/gcloud.compute.project-info.describe invocation-id/ecaeec2337e24223910c5efe1c6ac176 environment/None environment-version/None interactive/True from-script/False python/3.9.12 term/xterm-256color (Linux 5.10.147-20147-gbf231eecc4e8)'
== headers end ==
== body start ==
--===============2279194272988243142==
Content-Type: application/http
MIME-Version: 1.0
Content-Transfer-Encoding: binary
Content-ID: <8efd7e4e-8c7a-4d3c-9d75-85e156e4231d+0>

GET /compute/v1/projects/tf-playground-svpc-net?alt=json HTTP/1.1
Content-Type: application/json
MIME-Version: 1.0
content-length: 0
user-agent: google-cloud-sdk
accept: application/json
accept-encoding: gzip, deflate
Host: compute.googleapis.com

--===============2279194272988243142==--

== body end ==
==== request end ====

>>> from email.mime.multipart import MIMEMultipart, MIMEBase
>>> msg = MIMEMultipart("mixed")
>>> base = MIMEBase("application", "html")
>>> base.set_payload('''GET /compute/v1/projects/tf-playground-svpc-net?alt=json HTTP/1.1
... Content-Type: application/json
... MIME-Version: 1.0
... content-length: 0
... user-agent: google-cloud-sdk
... accept: application/json
... accept-encoding: gzip, deflate
... Host: compute.googleapis.com
... ''')
>>> msg.attach(base)
>>> msg.as_string()
