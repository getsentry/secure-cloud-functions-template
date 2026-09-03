# function-cron

A Python 3.11 Cloud Function (gen2) that runs every hour, reads a plain
environment variable and a secret, and logs what it found.

Copy it into `functions/` to deploy:

```bash
cp -r examples/function-cron functions/my-function
```

Then rename `functions/my-function` and change the `name:` in its
`terraform.yaml` to match — the directory name is the resource name.

## Before it will apply

This example references the secret `test_key_1`. Declare it and give it a value
first, or `terraform plan` will stop and tell you it's missing:

```hcl
# terraform.tfvars
secrets = ["test_key_1"]
```

```bash
printf 'anything' | gcloud secrets versions add test_key_1 --data-file=-
```

If you don't need a secret, delete the whole `secrets:` block from
`terraform.yaml` and the `TEST_KEY_1` lines from `main.py`.

## What Terraform creates

- the function itself, in `region` from `terraform.tfvars`
- a dedicated runtime service account, `cf-<name>`, with only `logging.logWriter`
  plus `secretAccessor` on the secrets this function actually lists
- a Cloud Scheduler job, `<name>`, with its own service account `cj-<name>`
  holding only invoker on this one function

The function requires authentication. Cloud Scheduler calls it with an OIDC
token; nothing else can invoke it unless you grant that explicitly.

## Invoke it by hand

```bash
gcloud functions call function-cron --region=us-west1
```
