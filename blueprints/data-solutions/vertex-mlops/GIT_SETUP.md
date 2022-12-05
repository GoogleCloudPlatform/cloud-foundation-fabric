# MLOps with Vertex AI - GIT setup

## Introduction


Clone Google Cloud Professional services [repo](https://github.com/pbalm/professional-services/tree/vertex-mlops/examples/vertex_mlops_enterprise)
 to a temp directory and select the `vertex-mlops` branch: 
```
git clone https://github.com/pbalm/professional-services.git`
cd professional-services/
git checkout vertex-mlops
```

Setup your new Github repo.

Copy the `vertex_mlops_enterprise` folder to your local folder
```
cp -R ./examples/vertex_mlops_enterprise/* /<YOUR LOCAL FOLDER>
```

Commit the files in the dev branch (`main`):
```
git add *
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/<ORG>/<REPO>.git
git push -u origin main
```

## Branches
Create the additional branches in Github (`dev`, `staging`, `prod`). This can be also done from the UI (`Create branch: staging from main`).

Checkout the staging branch with `git checkout staging`.

Edit the yml files in the `.github/workflows` folder to set up correctly the references to the staging project in GCP.

Edit the yaml files in the `build` folder to set up correctly the references to the staging project in GCP.


## Accessing GitHub from Cloud Build via SSH keys
https://cloud.google.com/build/docs/access-github-from-build

```
mkdir workingdir
cd workingdir
ssh-keygen -t rsa -b 4096 -N '' -f id_github -C <GITHUB_EMAIL>
ssh-keyscan -t rsa github.com > known_hosts.github
zip known_hosts.github.zip known_hosts.github
```

Store the private SSH key in Secret Manager, in the `github-key` secret.

Add the public SSH key to your private repository's deploy keys.


