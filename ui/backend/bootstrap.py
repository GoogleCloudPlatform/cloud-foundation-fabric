import os
from google.cloud import storage, secretmanager

def create_gcs_bucket(bucket_name, project_id):
    """Creates a GCS bucket."""
    storage_client = storage.Client(project=project_id)
    bucket = storage_client.bucket(bucket_name)
    if not bucket.exists():
        bucket.create(location="US")
        print(f"Bucket {bucket_name} created.")
    else:
        print(f"Bucket {bucket_name} already exists.")

from google.api_core import exceptions

def create_secret(secret_id, project_id):
    """Creates a secret in Secret Manager."""
    client = secretmanager.SecretManagerServiceClient()
    parent = f"projects/{project_id}"
    try:
        client.create_secret(
            request={
                "parent": parent,
                "secret_id": secret_id,
                "secret": {"replication": {"automatic": {}}},
            }
        )
        print(f"Secret {secret_id} created.")
    except exceptions.AlreadyExists:
        print(f"Secret {secret_id} already exists.")

if __name__ == "__main__":
    PROJECT_ID = os.environ.get("GCP_PROJECT_ID")
    if not PROJECT_ID:
        raise ValueError("GCP_PROJECT_ID environment variable not set.")

    BUCKET_NAME = f"{PROJECT_ID}-tfstate"
    create_gcs_bucket(BUCKET_NAME, PROJECT_ID)

    # Example secret - in a real application, you'd create secrets for all sensitive variables
    create_secret("terraform-service-account-key", PROJECT_ID)