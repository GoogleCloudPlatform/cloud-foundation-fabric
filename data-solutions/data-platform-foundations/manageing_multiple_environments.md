# Manageing Multiple Environments

Terraform is a great tool for provisioning immutable infrastructure.
There are several ways to get Terraform to provision different environments using one repo. Here I’m going to use the most basic and naive method - the State separation.
State separation signals more mature usage of Terraform but with additional maturity comes additional complexity.
There are two primary methods to separate state between environments: directories and workspaces. I’m going to use the directory method.

For this example I’ll assume we have 3 environments:

- Dev
- QA
- Prod

```bash
export data_platform_folder="dpm"

mkdir ${data_platform_folder}
cd ${data_platform_folder}

git clone https://github.com/yorambenyaacov/cloud-foundation-fabric.git dev

git clone https://github.com/yorambenyaacov/cloud-foundation-fabric.git prod

git clone https://github.com/yorambenyaacov/cloud-foundation-fabric.git qa
```

Now you have a directory per environment in which you can do all the needed configurations (tfvars files) and provision it.
