dns_policy_rules = {
  accounts = {
    dns_name = "accounts.google.com."
    behavior = "bypassResponsePolicy"
  }
  aiplatform-notebook-cloud-all = {
    dns_name   = "*.aiplatform-notebook.cloud.google.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  aiplatform-notebook-gu-all = {
    dns_name   = "*.aiplatform-notebook.googleusercontent.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  appengine = {
    dns_name   = "appengine.google.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  appspot-all = {
    dns_name   = "*.appspot.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  backupdr-cloud = {
    dns_name   = "backupdr.cloud.google.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  backupdr-cloud-all = {
    dns_name   = "*.backupdr.cloud.google.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  backupdr-gu = {
    dns_name   = "backupdr.googleusercontent.google.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  backupdr-gu-all = {
    dns_name   = "*.backupdr.googleusercontent.google.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  cloudfunctions = {
    dns_name   = "*.cloudfunctions.net."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  cloudproxy = {
    dns_name   = "*.cloudproxy.app."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  composer-cloud-all = {
    dns_name   = "*.composer.cloud.google.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  composer-gu-all = {
    dns_name   = "*.composer.googleusercontent.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  datafusion-all = {
    dns_name   = "*.datafusion.cloud.google.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  datafusion-gu-all = {
    dns_name   = "*.datafusion.googleusercontent.com."
    local_data = { CNAME = { rrdatas = ["private.googleapis.com."] } }
  }
  dataproc = {
    dns_name = "dataproc.cloud.google.com."
  }
}
