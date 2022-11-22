# MLOps with Vertex AI - GIT setup

## Introduction


Clone Google Cloud Professional services repo to a temp directory and select the `vertex-mlops` branch: 
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
