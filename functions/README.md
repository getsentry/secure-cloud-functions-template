# Cloud Functions

Every subdirectory of `functions/` that contains a `terraform.yaml` becomes a
Cloud Function (gen2). **The directory name is the function name** — the `name:`
field inside must match it.

## Add one

```bash
cp -r examples/function-cron functions/my-function
sed -i '' 's/^name: .*/name: my-function/' functions/my-function/terraform.yaml
```

1. Put your code in the folder (`main.py`, `requirements.txt`, …). Everything in
   it is zipped and deployed except `terraform.yaml`, `main.tf`, `README.md` and
   `.DS_Store`.
2. Make sure `function_entrypoint` matches the function name in your code.
3. Add a `README.md` explaining what it does.
4. Open a PR and read the plan.

Nothing outside your folder needs editing.

## Example

```yaml
name: my-function
description: what this function does

cloud-function-gen2:
  runtime: python311
  execution_timeout: 120
  available_memory: 256M
  function_entrypoint: main
  environment_variables:
    GCP_PROJECT: $project
    GREETING: hello
  secrets:
    - key: TEST_KEY_1
      secret: test_key_1
      version: latest

cron:
  schedule: "0 * * * *"
  time_zone: America/New_York
```

Unknown keys are a **plan-time error** naming the file and the key, so a typo
can't silently deploy the wrong thing.

## Reference

### Top level

| Key | Description | Required | Default |
|---|---|---|---|
| `name` | Must equal the directory name | yes | — |
| `description` | Free text | no | null |
| `cloud-function-gen2` | The function itself | yes | — |
| `cron` | Also create a Cloud Scheduler job | no | — |

### `cloud-function-gen2`

| Key | Description | Required | Default |
|---|---|---|---|
| `runtime` | e.g. `python311`, `nodejs20`, `go122` | no | `python311` |
| `function_entrypoint` | Name of the handler in your code | no | `main` |
| `execution_timeout` | Seconds before the function is killed (1–3600) | no | `60` |
| `available_memory` | e.g. `256M`, `1Gi` | no | `256M` |
| `environment_variables` | Map of env vars; see `$name` below | no | `{}` |
| `secrets` | Secrets mounted as env vars; see below | no | `[]` |
| `ingress_settings` | `ALLOW_ALL`, `ALLOW_INTERNAL_ONLY`, `ALLOW_INTERNAL_AND_GCLB` | no | `ALLOW_ALL` |
| `min_instances` | Warm instances; 0 scales to zero | no | `0` |
| `max_instances` | Caps concurrency, and your bill | no | `10` |
| `allow_unauthenticated` | Grant `allUsers` invoker — see warning | no | `false` |

The key is `execution_timeout`, **not** `timeout`.

### `cron`

| Key | Description | Required | Default |
|---|---|---|---|
| `schedule` | 5-field cron, quoted: `"0 * * * *"` | yes | — |
| `time_zone` | e.g. `America/New_York` | no | `Etc/UTC` |
| `attempt_deadline` | Give up after, e.g. `320s` (max `1800s`) | no | `320s` |
| `http_method` | `GET`, `POST`, … | no | `GET` |
| `description` | Overrides the top-level description | no | inherits |

### `secrets`

```yaml
secrets:
  - key: MY_ENV_VAR     # the env var name your code reads
    secret: my_secret   # must be listed in `secrets` in terraform.tfvars
    version: latest
```

The secret must be declared in the root `secrets` variable **and** have a value
added out of band. Referencing an undeclared secret fails at plan time with the
name of the file and the missing secret. See
[secrets/readme.md](../secrets/readme.md).

### `$name` substitution

A value of `$name` in `environment_variables` is replaced with the matching
entry from `terraform.tfvars`. `project`, `region`, `zone` and `owner` always
work; add your own under `template_variables`. A `$name` with no match is passed
through unchanged, `$` included.

## What you get per function

- the function, in `region` from `terraform.tfvars`
- a dedicated runtime service account `cf-<name>`, holding only
  `roles/logging.logWriter` plus `secretAccessor` on the secrets it lists
- with a `cron` block: a Cloud Scheduler job `<name>` and its own service
  account `cj-<name>`, holding invoker on this one function only

## Two things worth knowing

> **`allow_unauthenticated: true` grants `allUsers` the invoker role** on both
> the function and its underlying Cloud Run service — anyone on the internet can
> call it with no credentials. Only use it for public webhook receivers that
> verify requests themselves (signature check, shared secret in the body).

> **`ingress_settings` is network reachability, not authorisation.** The default
> `ALLOW_ALL` means the endpoint is reachable from the internet, but callers
> still need `roles/cloudfunctions.invoker` unless `allow_unauthenticated` is
> set. `ALLOW_ALL` is the default because Cloud Scheduler reaches functions over
> the public endpoint. If a function has no external callers, set
> `ingress_settings: ALLOW_INTERNAL_AND_GCLB` and confirm its callers still
> work.
