project           = "jeffreyhung-test"
region            = "us-west1"
zone              = "us-west1-b"
project_id        = "jeffreyhung-test"
project_num       = "546928617664"
bucket_location   = "US-WEST1"
tf_state_bucket   = "jeffreyhung-test-tfstate"
alerts_collection = "alerts"
# provide the service account email for deployment if you want to use your own workload identity provider
# if you want to spin up new workload identity pool, set this to null
deploy_sa_email = null