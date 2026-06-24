# Secure Cloud Functions Template
A template to quickly spin up cloud functions and cron jobs in GCP using terraform, with dedicated/least-privileged service account and secure by default settings

## Setup
Update the local variables in `terraform.tfvars` with your own GCP project and settings
```
  project           = "project-name"
  region            = "us-west1"
  zone              = "us-west1-b"
  project_id        = "project-id"
  project_num       = "1234567890"
  bucket_location   = "US-WEST1"
```
also update the `workload_identity_provider` and `service_account` in both the `.github/workflows/terraform-apply.yaml` and `.github/workflows/terraform-plan.yaml` file to match what you have in Terraform.

## Two deployment identities (plan vs apply)
This template provisions **two** service accounts instead of one, because `terraform plan` runs on pull requests and therefore executes attacker-controllable configuration (Terraform data sources and providers run during `plan`):

- **`gha-cf-tf-plan`** — read-only. It gets `roles/viewer` + `roles/iam.securityReviewer` (resource + IAM-policy reads), `roles/iam.workloadIdentityPoolViewer` (WIF reads), a custom role for `storage.buckets.get` (bucket metadata), object read/lock on the **state** bucket, and object read on the **staging** bucket only. Used by the `terraform plan` workflow on pull requests. It cannot write resources, cannot read secret values, and cannot read object contents of other buckets (e.g. pub/sub sinks), so a malicious PR cannot escalate or exfiltrate through it.
- **`gha-cloud-functions-deployment`** — privileged. Used by the `terraform apply` workflow. Its workload-identity binding is pinned to the GitHub **`production` environment subject** (`repo:<org>/<repo>:environment:production`), not merely to `refs/heads/main` — so the approval gate is enforced at the **GCP IAM layer**: only a job that declares `environment: production` can mint this token, and no other main-triggered workflow can. It holds **no** `secretmanager.secretAccessor` (secret *management* — create + set IAM, without reading values — is granted via a narrow custom role). It does hold project-wide `roles/iam.serviceAccountUser` so it can `actAs` the per-resource runtime SAs it deploys; this is the narrowest grant that supports autonomous function onboarding (see the NOTE in `infrastructure/permissions.tf` for why it can't be scoped further, and the more-locked-down alternative).

> **Bootstrap note:** Neither CI identity holds project-IAM-admin, so any apply that changes **project-level IAM** — including granting the plan SA its roles on first run — must be run by a principal with `roles/owner` or `roles/resourcemanager.projectIamAdmin`. Run the initial/permission-changing `apply` as such an admin, not as the plan or apply SA.

### Required: the `production` environment
The `terraform apply` workflow runs in the GitHub Environment named **`production`**. This is **required**, not optional: the apply SA's workload-identity binding only matches tokens whose subject is `repo:<org>/<repo>:environment:production`, which a job gets only by declaring `environment: production`. Create it under `Settings > Environments` and add:
- **Required reviewers** — so a human approves before the privileged service account is ever used.
- **Deployment branch rule** limiting the environment to `main`.

If the environment doesn't exist, GitHub auto-creates it on first run with no protection — apply still authenticates (the subject still includes `environment:production`), but without the human approval gate until you add reviewers. A workflow that does **not** declare `environment: production` cannot obtain the apply token at all.

### Initial Run
On the first run, you will have to manually create the GCS bucket in your GCP project to store the TF state, then import it 
then with `terraform import google_storage_bucket.tf-state tf-state` after you run `terraform init` and `terraform plan`.

> The state bucket is created with `force_destroy = false` and `lifecycle { prevent_destroy = true }` so it cannot be deleted by accident. To intentionally tear it down you must first remove that lifecycle block.

Once the GCS bucket that stores terraform backend is created and imported, you can then run the following to setup all the required permissions and service accounts. 

```bash
terraform init # initiate terraform and install all the required providers
terraform plan # perform a plan to show what will be changed based on your terraform setting
terraform apply # apply the changes to production
```
If you are running this in a brand new GCP project, it's very likely that the first few terraform apply will fail, as enabling all the API will take some time on the GCP side, it's suggested to re-run terraform apply after 15-20 minutes if it failed initially.

You will also run into a Catch 22 where GCP bucket that stores the terraform states needs to be created before you can use the GCS backend, hence some manually deployment will be required when you first setup the project. It is suggested to initiate the project without the GCS backend and have the basic settings configured and ready, then include the GCS backend and do a `terraform init -migrate-state` to migrate the terraform state from your local device to GCS bucket.


# BYO workload identity provider and service account
For Sentry employees who want to utilize this template, you will be able to create service account in [security-as-code](https://github.com/getsentry/security-as-code) and grant it access to our existing workload identity provider/pool without creating a new one.

You can create the service account in the [iac-security/env/prod/terraform.tfvars](https://github.com/getsentry/security-as-code/blob/main/iac-security/env/prod/terraform.tfvars) in security-as-code and grant it access to repos that you created base on this template ([Example](https://github.com/getsentry/security-as-code/blob/beed2427d34b22edb44dfad2a822389b4a6c352c/iac-security/env/prod/terraform.tfvars#L184-L190)) 

Once that's set, you can update this repo with the following steps to configure it to use your service account:
- In `terraform.tfvars`, set the `deploy_sa_email` as the service account you created. 
- Update `.github/workflows/terraform-plan.yaml` and `.github/workflows/terraform-apply.yaml` with your workload_identity_provider and service_account in the `gcp auth` step

> **Note on BYO mode and the plan/apply split:** When `deploy_sa_email` is set, this repo does **not** create the `gha-cf-tf-plan` / `gha-cloud-functions-deployment` accounts — you bring a single account. For the same least-privilege benefit, create a separate read-only account in security-as-code for the `terraform plan` workflow and a privileged one (scoped to `refs/heads/main`) for `terraform apply`, then point each workflow at the matching account.

# CI/CD (Continuous Integrations and Continuous Deployments)
We have GitHub Action workflows in place, running `terraform plan` on Pull Requests ([workflow](.github/workflows/terraform-plan.yaml)) and running `terraform apply` on merge to main ([workflow](.github/workflows/terraform-apply.yaml)).

When you created a Pull Request to main on this repository, `terraform plan` will run automatically and post the output of the plan in a comment to your Pull Request. You can inspect and review the output before merging your PRs. This runs as the **read-only** `gha-cf-tf-plan` identity.

Once merged, `terraform apply` will kick in and apply changes to ensure your environment matches terraform state. It runs as the privileged `gha-cloud-functions-deployment` identity inside the protected `production` environment, so it waits for reviewer approval (once you've configured required reviewers) before any privileged action is taken.

# Secrets Management

See [secrets/readme.md](secrets/readme.md) for details.