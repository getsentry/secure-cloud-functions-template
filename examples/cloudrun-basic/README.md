# cloudrun-basic

A Flask service on Cloud Run, built from the `Dockerfile` in this folder, with
an hourly Cloud Scheduler job calling `/tasks/hourly`.

Copy it into `cloudruns/` to deploy:

```bash
cp -r examples/cloudrun-basic cloudruns/my-service
sed -i '' 's/^name: .*/name: my-service/' cloudruns/my-service/terraform.yaml
```

The directory name is the service name **and** the image name, so it has to
match the `name:` field. A mismatch fails at `terraform plan`.

## How the image gets built

You don't build or push anything by hand. On merge to `main`, the apply workflow
builds every `cloudruns/*/Dockerfile`, pushes it to Artifact Registry tagged with
the commit SHA, and then Terraform deploys that exact tag.

On a pull request the image is built but **not** pushed, purely to catch a
broken `Dockerfile` before merge.

If you already publish this image from somewhere else, set `image:` in
`terraform.yaml` and the build is skipped entirely:

```yaml
cloud-run:
  image: us-west1-docker.pkg.dev/other-project/repo/my-service:v1.2.3
```

## Two things the container must do

1. **Listen on `$PORT`, on `0.0.0.0`.** Cloud Run sets `PORT` (8080 here, from
   the `port` key). Binding to `localhost` means Cloud Run can never reach the
   container and the deploy times out with a confusing health-check error.
2. **Start quickly.** Cloud Run waits for the port to open before sending
   traffic. Do slow setup lazily, not at import time.

## What Terraform creates

- the Cloud Run service, in `region` from `terraform.tfvars`
- a dedicated runtime service account, `cr-<name>`, holding only
  `logging.logWriter` plus `secretAccessor` on the secrets this service lists
- with a `cron` block: a Cloud Scheduler job `<name>-cron` and its own service
  account `crc-<name>`, holding `run.invoker` on this one service

The service requires authentication — Cloud Scheduler calls it with an OIDC
token, and nothing else can invoke it unless you grant that explicitly.

## Call it yourself

```bash
gcloud run services proxy my-service --region=us-west1
```

Then open <http://localhost:8080>. The proxy authenticates as you, so this works
without making the service public.

## Cloud Run or a Cloud Function?

Use a **function** ([functions/](../../functions/README.md)) for a single Python
handler with no container to maintain. Use **Cloud Run** when you need a
Dockerfile, a non-Python runtime, a web framework with routes, long-lived
connections, or fine control over CPU, concurrency and scaling.
