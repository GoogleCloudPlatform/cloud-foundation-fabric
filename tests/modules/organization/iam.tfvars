group_iam = {
  "owners@example.org" = [
    "roles/owner",
    "roles/resourcemanager.folderAdmin"
  ],
  "viewers@example.org" = [
    "roles/viewer"
  ]
}
iam = {
  "roles/owner" = [
    "user:one@example.org",
    "user:two@example.org"
  ],
  "roles/browser" = [
    "domain:example.org"
  ]
}
