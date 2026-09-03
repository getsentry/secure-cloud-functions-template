# libraries/

Shared Python packages that several Cloud Functions can depend on, instead of
copy-pasting the same helper into each function folder.

## Status: not wired up yet

**There is no CI that builds or publishes these.** An earlier version of this
file claimed "the CI handles building the wheel and uploading after merging" —
that workflow does not exist in this repo. Until it does, a library here is just
source code; nothing consumes it automatically.

If you need shared code today, the options that work are:

1. **Vendor it.** Copy the module into each function's folder. Ugly, but it
   deploys, and function source folders are small.
2. **Publish it yourself.** Build a wheel and push it to an Artifact Registry
   Python repository by hand, then reference it as below.

Contributions welcome for the missing workflow: it needs an Artifact Registry
Python repository (this template doesn't create one yet), a build step, and a
publish step gated on the `production` environment like `terraform apply` is.

## Add a library

1. Create a folder under `libraries/`
2. Add a `setup.py` (see `example/`)
3. Bump the version when you change it — Artifact Registry rejects overwriting
   an existing version

## Reference one from a function

In the function's `requirements.txt`:

```
--extra-index-url https://<region>-python.pkg.dev/<project>/<repository>/simple/

your-library==1.0.0
```

The function's runtime service account needs
`roles/artifactregistry.reader` on the repository, which this template does not
grant yet — another reason the above is manual for now.
