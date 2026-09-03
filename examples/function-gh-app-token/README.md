# function-gh-app-token

Mints a short-lived (1 hour) GitHub App installation token on request. Useful
when you'd otherwise store a long-lived personal access token in a secret.

Copy it into `functions/` to deploy:

```bash
cp -r examples/function-gh-app-token functions/gh-app-token
```

## Before it will apply

Declare all three secrets and add their values, or `terraform plan` will stop
and name the ones it can't find:

```hcl
# terraform.tfvars
secrets = ["GH_APP_ID", "GH_APP_INSTALLATION_ID", "GH_APP_PRI_KEY"]
```

```bash
printf '123456' | gcloud secrets versions add GH_APP_ID --data-file=-
printf '7654321' | gcloud secrets versions add GH_APP_INSTALLATION_ID --data-file=-
gcloud secrets versions add GH_APP_PRI_KEY --data-file=/path/to/app.private-key.pem
```

## Where to find each value

### GH_APP_ID

`GitHub Settings` > `Developer settings` > `GitHub Apps` > *your app* > `App ID`,
or <https://github.com/settings/apps/\<APP NAME>>.

### GH_APP_INSTALLATION_ID

`GitHub Settings` > `Integrations` > `Applications` > *your app*. The ID is the
last path segment of the URL you land on:

- <https://github.com/organizations/\<org>/settings/installations/\<ID>>
- <https://github.com/settings/installations/\<ID>>

### GH_APP_PRI_KEY

Generate under `GitHub Settings` > `Developer settings` > `GitHub Apps` > *your
app* > `Private Key`. Upload the `.pem` **file as-is** with
`--data-file=`; don't paste it or convert newlines to `\n` — the PEM parser
needs the real line breaks, and `gcloud` preserves them.

## Output

```json
{ "token": "ghs_...", "expires_at": "2026-09-01T13:00:00Z" }
```

The function requires authentication, so only principals you've granted
`roles/cloudfunctions.invoker` can call it. The token is deliberately never
logged — Cloud Logging is readable by a much wider group (anyone with
`roles/logging.viewer`) than the set of allowed invokers.
