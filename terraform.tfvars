# ---------------------------------------------------------------------------
# Run `sbin/bootstrap` to fill this file in interactively, or edit it by hand.
# Every value below is validated -- a bad value fails fast at `terraform plan`
# with an explanation, rather than as an opaque API error minutes later.
# ---------------------------------------------------------------------------

# Your GCP project ID, and its numeric project number.
# gcloud projects describe <project> --format='value(projectNumber)'
project     = "CHANGEME"
project_num = "CHANGEME"

# Where regional resources (functions, workflows, schedulers) are created.
region = "us-west1"
zone   = "us-west1-b"

# Location for the buckets this template creates. Uppercase.
# Use a multi-region (US, EU) or a single region (US-WEST1).
bucket_location = "US-WEST1"

# The GitHub repo allowed to authenticate via workload identity, "owner/repo".
# Tokens from any other repository are rejected at the provider level.
github_repository = "CHANGEME/CHANGEME"

# Owning team. Applied as the `owner` label on every resource.
# Must be a valid GCP label value: lowercase, no spaces.
owner = "team-security"

# Secret Manager secrets to create. Names only -- values are added out of band,
# see secrets/readme.md. Start empty and add as your functions need them.
secrets = []

# Extra values you want to reference from a terraform.yaml as `$name`.
# `project`, `region`, `zone` and `owner` are always available already.
template_variables = {}

# Bring-your-own service account for `terraform apply`. Leave null to have this
# template create its own workload identity pool and service accounts.
# Sentry employees: see the "BYO workload identity" section of the README.
deploy_sa_email = null
