To create resources in this example run

- terraform init
- terraform apply -var project_id=$GOOGLE_CLOUD_PROJECT

Replace the $GOOGLE_CLOUD_PROJECT variable in the command above if you need to
create resources in a different project from the one set in the Cloud Shell.

Once resources have been created, run the command to create the feed shown in
the Terraform outputs, then refer to the README file for testing.

To persist state, copy the sample backend file and enter a valid GCS bucket

- cp backend.tf.sample backend.tf
- vi backend.tf

To destroy the example once done run this command

- terraform destroy