# Third Party Solutions

The blueprints in this folder show how to automate installation of specific third party products on GCP, following typical best practices.

## Blueprints

### F5 BigIP

<a href="./f5-bigip/" title="F5 BigIP"><img src="./phpipam/diagram.png" align="left" width="320px"></a> <p style="margin-left: 340px">These examples show how to deploy F5 BigIP-VE load balancers in GCP.</p>

<br clear="left">

### Gitlab Runner

<a href="./gitlab-runner/" title="Gitlab Runner"><img src="./gitlab-runner/images/docker-autoscaler.png" align="left" width="320px"></a> <p style="margin-left: 340px">These [example](./gitlab-runner/) show how to deploy a Gitlab runner in GCP.</p>

<br clear="left">

### Gitlab

<a href="./gitlab/" title="Gitlab"><img src="./gitlab/diagram.png" align="left" width="320px"></a> <p style="margin-left: 340px">This blueprint shows how to deploy a Gitlab instance in GCP. The architecture is based on the reference described in the [official documentation](https://docs.gitlab.com/ee/administration/reference_architectures/1k_users.html) with managed services such as Cloud SQL, Memorystore and Cloud Storage.</p>

<br clear="left">

### OpenShift cluster bootstrap on Shared VPC

<a href="./openshift/" title="HubOpenShift bootstrap example"><img src="./openshift/diagram.png" align="left" width="320px"></a> <p style="margin-left: 340px"> This [example](./openshift/) shows how to quickly bootstrap an OpenShift 4.7 cluster on GCP, using typical enterprise features like Shared VPC and CMEK for instance disks. </p>

<br clear="left">

### Serverless phpIPAM on Cloud Run

<a href="./phpipam/" title="phpIPAM bootstrap example"><img src="./phpipam/images/phpipam.png" align="left" width="320px"></a> <p style="margin-left: 340px">This [example](./phpipam/) shows how to quickly bootstrap a serverless phpIPAM instance on GCP using Cloud Run. This comes with typical enterprise features like Shared VPC, Cloud Armor with IAP and, possibly, private exposure via Internal Application Load Balancer. Indeed, the script supports deploying the application either publicly via Global Application Load Balancer with restricted access based on IPs (Cloud Armor) and identities (Identity Aware Proxy) or privately via Internal Application Load Balancer.</p>

<br clear="left">

### Wordpress deployment on Cloud Run

<a href="./wordpress/cloudrun/" title="Wordpress deployment on Cloud Run"><img src="./wordpress/cloudrun/images/architecture.png" align="left" width="320px"></a> <p style="margin-left: 340px"> This [example](./wordpress/cloudrun/) shows how to deploy a functioning new Wordpress website exposed to the public internet via CloudRun and Cloud SQL, with minimal technical overhead. </p>

<br clear="left">
