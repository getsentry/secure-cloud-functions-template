"""Minimal Cloud Run service.

Cloud Run gives the container a port to listen on via $PORT and routes all
traffic to it. Anything that speaks HTTP works; this uses Flask.
"""

import os

from flask import Flask

app = Flask(__name__)


@app.get("/")
def index():
    return {
        "project": os.environ.get("GCP_PROJECT", "<unset>"),
        "greeting": os.environ.get("GREETING", "<unset>"),
    }, 200


@app.post("/tasks/hourly")
def hourly():
    """Called by the Cloud Scheduler job defined in terraform.yaml.

    Cloud Scheduler treats any 2xx as success and retries anything else.
    """
    print("hourly task ran")
    return {"status": "ok"}, 200


if __name__ == "__main__":
    # Only used for local development; in the image gunicorn serves the app.
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
