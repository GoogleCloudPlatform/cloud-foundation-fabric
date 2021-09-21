import click
from googleapiclient.errors import Error
from googleapiclient import discovery
from oauth2client.client import GoogleCredentials

credentials = GoogleCredentials.get_application_default()
iam_service = discovery.build("iam", "v1", credentials=credentials)

SENSITIVE_PERMISSIONS = {
    "resourcemanager.projects.setIamPolicy",
    "resourcemanager.folders.setIamPolicy",
    "resourcemanager.organizations.setIamPolicy",
}


def get_role_permissions(role):
    if role.startswith("roles/"):
        endpoint = iam_service.roles()
    elif role.startswith("projects/"):
        endpoint = iam_service.projects().roles()
    elif role.startswith("organizations/"):
        endpoint = iam_service.organizations().roles()
    else:
        raise Exception(f"Invalid role {role}")

    response = endpoint.get(name=role).execute()
    permissions = response.get("includedPermissions")
    return permissions


@click.command()
@click.argument("file", type=click.File("r"))
def main(file):
    """Verify that the set of GCP roles in FILE does not include the
    permission SetIamPolicy at project, folder or organization level

    This program authenticates against GCP using default application
    credentials to query project and organization level roles.

    """
    clean_roles = [x.rstrip(" \n") for x in file]
    roles = (x for x in clean_roles if x)

    allok = True
    for role in roles:
        try:
            permissions = set(get_role_permissions(role))
        except Error as e:
            print(f"WARNING: can't read {role}: {e}")
            allok = False
        else:
            matched_sensitive_permissions = SENSITIVE_PERMISSIONS & permissions
            if matched_sensitive_permissions:
                print(f"WARNING: {role} contains {matched_sensitive_permissions}")
                allok = False
            else:
                print(f"{role} ok")

    exit(0 if allok else 1)


if __name__ == "__main__":
    main()
