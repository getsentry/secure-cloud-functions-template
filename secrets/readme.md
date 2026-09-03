# Secrets

Terraform creates the secret **container**; you add the **value** out of band.
Secret values are never in this repo, never in Terraform state, and never in a
plan output.

## Add a secret

**1. Declare the name** in `terraform.tfvars`:

```hcl
secrets = ["my_api_token"]
```

**2. Apply**, which creates the empty secret.

**3. Add the value:**

```bash
printf 'the-actual-value' | gcloud secrets versions add my_api_token --data-file=-
```

Use `printf`, not `echo` — `echo` appends a newline that becomes part of the
secret and causes authentication failures that are very annoying to debug. For a
file (a PEM key, a JSON credential) pass it directly, which preserves newlines
exactly:

```bash
gcloud secrets versions add my_api_token --data-file=/path/to/key.pem
```

**4. Reference it** from a function's `terraform.yaml`:

```yaml
secrets:
  - key: MY_API_TOKEN     # env var name your code reads
    secret: my_api_token  # must match the name in `secrets`
    version: latest
```

Referencing a secret that isn't in `secrets` fails at `terraform plan` with the
file name and the missing secret, rather than at apply.

## The ordering problem

A function can't be deployed with a secret that has no value — GCP rejects it.
So creating a secret and attaching it to a function in one `terraform apply`
fails partway through.

**Do it in two applies.** This is the only approach worth using:

1. Add the name to `secrets`, apply. The empty secret now exists.
2. Add the value with `gcloud secrets versions add`.
3. Add the `secrets:` block to your function's `terraform.yaml`, apply.

Doing both in one apply also works if you don't mind a red build: the secret is
still created before the failure, so add the value and re-run the same apply.
Anything faster than that is a race, and losing it just means a failed apply.

## Rotating a secret

Add a new version; `version: latest` picks it up on the next function deploy.

```bash
printf 'new-value' | gcloud secrets versions add my_api_token --data-file=-
gcloud functions deploy my-function --region=us-west1  # or re-apply
```

Pin `version` to a specific number instead of `latest` if you need a function to
keep using a known version across rotations.

## Removing a secret

Secrets are created with `prevent_destroy`, so removing a name from `secrets`
makes Terraform **fail** rather than delete it. That's on purpose: deleting a
secret destroys every version irreversibly, and removing a line is easy to do by
accident in a large diff.

To really delete one: remove the `secrets:` reference from every function,
delete the name from `secrets`, remove the `prevent_destroy` block from
[secrets.tf](secrets.tf), then apply.

## Who can read what

- The **apply** service account can create and manage secrets and their IAM, but
  holds **no** `secretmanager.secretAccessor` — CI cannot read values.
- The **plan** service account has no secret access at all.
- Each function's runtime service account gets `secretAccessor` on **only** the
  secrets its own `terraform.yaml` lists.

Never `print()` a secret value. Cloud Logging is readable by anyone with
`roles/logging.viewer`, which is a much wider group than the callers of your
function.
