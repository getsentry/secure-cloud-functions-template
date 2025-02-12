# Secure Cloud Functions Template
A template to quickly spin up cloud functions and cron jobs in GCP using terraform, with dedicated/least-privileged service account and secure by default settings

## Setup
update the local variables in `terraform.tfvars` with your own GCP project and settings
```
  project           = "jeffreyhung-test"
  region            = "us-west1"
  zone              = "us-west1-b"
  project_id        = "jeffreyhung-test"
  project_num       = "546928617664"
  bucket_location   = "US-WEST1"
```
also update the `workload_identity_provider` and `service_account` in both the `.github/workflows/terraform-apply.yaml` and `.github/workflows/terraform-plan.yaml` file to match what you have in Terraform.

### Initial Run

On the first run, you will have to manually create the GCS bucket in your GCP project to store the TF state, then import it 
then with `terraform import google_storage_bucket.tf-state tf-state` after you run `terraform init` and `terraform plan`.

Once the GCS bucket that stores terraform backend is created and imported, you can then run the following to setup all the required permissions and service accounts. 

```bash
terraform init # initate terraform and install all the required providers
terraform plan # perform a plan to show what will be changed base on your terraform setting
terraform apply # apply the changes to production
```
If you are running this in a brand new GCP project, it's very likely that the first few terraform apply will fail, as enabling all the API will take some time on the GCP side, it's suggested to re-run terraform apply after 15-20 minutes if it failed initially.

You will also run into a Catch 22 where GCP bucket that stores the terraform states needs to be created before you can use the GCS backend, hence some manually deployment will be required when you first setup the project. It is suggested to initiate the project without the GCS backend and have the basic settings configured and ready, then include the GCS backend and do a `terraform init -migrate-state` to migrate the terraform state from your local device to GCS bucket.


# BYO workload identity provider and service account
For Sentry employees who want to utilize this template, you will be able to create secivce account in [security-as-code](https://github.com/getsentry/security-as-code) and grant it access to our existing workload identity provider/pool without creating a new one.

You can create the sevice account in the [iac-security/env/prod/terraform.tfvars](https://github.com/getsentry/security-as-code/blob/main/iac-security/env/prod/terraform.tfvars) in security-as-code and grant it access to repos that you created base on this template ([Example](https://github.com/getsentry/security-as-code/blob/beed2427d34b22edb44dfad2a822389b4a6c352c/iac-security/env/prod/terraform.tfvars#L184-L190)) 

Once that's set, you can update this repo with the following steps to config it to use your service account:
- In `terraform.tfvars`, set the `deploy_sa_email` as the service account you created. 
- Update `.github/workflows/terraform-plan.yaml` and `.github/workflows/terraform-apply.yaml` with your workload_identity_provider and service_account in the `gcp auth` step

# CI/CD (Continuous Integrations and Continuous Deployments)
We have GitHub Action workflows in place, running `terraform plan` on Pull Requests ([workflow](.github/workflows/terraform-plan.yaml)) and running `terraform apply` on merge to main ([workflow](.github/workflows/terraform-apply.yaml)).

When you created a Pull Request to main on this repository, `terraform plan` will run automatically and post the output of the plan in a comment to your Pull Request. You can inspect and review the output before merging your PRs.

Once merged, `terraform apply` will kick in and automatically apply changes to ensure your environment matches terraform state.
