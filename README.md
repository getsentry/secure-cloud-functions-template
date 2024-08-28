!!! WORK IN PROGRESS !!!

update the local variables in `main.tf` with your own GCP project and settings
```
locals {
  project           = "jeffreyhung-test"
  region            = "us-west1"
  zone              = "us-west1-b"
  project_id        = "jeffreyhung-test"
  project_num       = "546928617664"
  bucket_location   = "US-WEST1"
  alerts_collection = "alerts"
  sentry_jira_url   = "https://getsentry.atlassian.net"
}
```
then run 

```
terraform init
terraform plan
terraform apply
```