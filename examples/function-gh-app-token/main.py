"""Mint a short-lived GitHub App installation token.

Installation tokens expire after an hour, which makes them a good alternative
to a long-lived personal access token stored in a secret.

Requires GH_APP_ID, GH_APP_INSTALLATION_ID and GH_APP_PRI_KEY as secret-backed
environment variables -- see terraform.yaml and README.md.
"""

import datetime
import os

import jwt
import requests

GITHUB_API = "https://api.github.com"
# GitHub rejects app JWTs with a lifetime over 10 minutes.
JWT_TTL_SECONDS = 9 * 60
# Clock skew allowance; GitHub rejects a JWT whose iat is in the future.
JWT_SKEW_SECONDS = 60


def _app_jwt(app_id: str, private_key: str) -> str:
    now = int(datetime.datetime.now(datetime.timezone.utc).timestamp())
    payload = {
        "iat": now - JWT_SKEW_SECONDS,
        "exp": now + JWT_TTL_SECONDS,
        "iss": app_id,
    }
    return jwt.encode(payload=payload, key=private_key, algorithm="RS256")


def get_installation_token(app_id: str, installation_id: str, private_key: str) -> dict:
    """Exchange the app's private key for an installation access token."""
    response = requests.post(
        f"{GITHUB_API}/app/installations/{installation_id}/access_tokens",
        headers={
            "Authorization": f"Bearer {_app_jwt(app_id, private_key)}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
        timeout=30,
    )
    # Raise before touching the body, so a 401 doesn't surface as a KeyError.
    response.raise_for_status()
    return response.json()


def main(request):
    # Read secrets inside the handler, not at import time: a missing secret then
    # fails one request with a clear error instead of crashing every cold start
    # with an unexplained KeyError.
    try:
        app_id = os.environ["GH_APP_ID"]
        installation_id = os.environ["GH_APP_INSTALLATION_ID"]
        private_key = os.environ["GH_APP_PRI_KEY"]
    except KeyError as missing:
        print(f"missing required secret env var: {missing}")
        return {"error": f"missing configuration: {missing}"}, 500

    try:
        token = get_installation_token(app_id, installation_id, private_key)
    except requests.HTTPError as exc:
        # Log the status, never the response body -- it can echo credentials.
        print(f"github rejected the token request: {exc.response.status_code}")
        return {"error": "could not mint token"}, 502
    except requests.RequestException as exc:
        print(f"github request failed: {type(exc).__name__}")
        return {"error": "could not reach github"}, 504

    # The function requires authentication (allow_unauthenticated is false), so
    # only callers you have granted invoker to can reach this.
    #
    # Do NOT print the token: Cloud Logging is readable by anyone with
    # roles/logging.viewer, which is a much wider group than the invokers.
    return {
        "token": token["token"],
        "expires_at": token["expires_at"],
    }, 200
