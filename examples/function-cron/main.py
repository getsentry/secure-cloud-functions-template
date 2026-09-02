"""Minimal Cloud Function (gen2) invoked on a schedule by Cloud Scheduler.

The entrypoint name must match `function_entrypoint` in terraform.yaml
(`main`, by default).
"""

import os


def main(request):
    project = os.environ.get("GCP_PROJECT", "<unset>")
    region = os.environ.get("GCP_REGION", "<unset>")
    greeting = os.environ.get("GREETING", "<unset>")

    # Never log a secret value: Cloud Logging is readable by anyone with
    # roles/logging.viewer, a much wider group than this function's callers.
    has_secret = "TEST_KEY_1" in os.environ

    print(f"running in {project}/{region}, greeting={greeting}, secret_present={has_secret}")

    # Cloud Scheduler treats any 2xx as success and retries anything else.
    return "ok", 200
