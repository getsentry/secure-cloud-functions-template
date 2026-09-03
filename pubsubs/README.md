# Pub/Sub

Every subdirectory of `pubsubs/` that contains a `terraform.yaml` becomes a
Pub/Sub topic with a subscription, optionally archived to GCS. **The directory
name is the config name** — the `name:` field inside must match it.

## Add one

```bash
cp -r examples/pubsub-basic pubsubs/my-topic
sed -i '' 's/^name: .*/name: my-topic/' pubsubs/my-topic/terraform.yaml
```

## Example

```yaml
name: my-topic
description: what flows through this topic

pubsub:
  topic_name: my-topic
  subscription_id: my-subscription
  service_account_id: my-topic-sa
  service_account_display_name: My Topic Consumer
  ttl: "604800s"          # optional, 7 days

sink:                     # optional
  sink_name: my-archive
  retention_days: 30
```

## Reference

### Top level

| Key | Description | Required | Default |
|---|---|---|---|
| `name` | Must equal the directory name | yes | — |
| `description` | Free text | no | null |
| `pubsub` | The topic and its subscription | yes | — |
| `sink` | Also archive every message to GCS | no | — |

### `pubsub` (required)

| Key | Description | Required | Default |
|---|---|---|---|
| `topic_name` | Name of the topic | yes | — |
| `subscription_id` | Name of the pull subscription | yes | — |
| `service_account_id` | Service account for whatever consumes the subscription | yes | — |
| `service_account_display_name` | Display name for that account | yes | — |
| `ttl` | Idle time before Pub/Sub deletes the subscription. **Duration string in seconds**, e.g. `"604800s"`. Omit for never. | no | never |

> `ttl` must be a duration string like `"604800s"`. An earlier version of these
> docs showed `ttl: 7`, which is not valid and fails at apply. A bad value now
> fails at plan with an explanation.

The topic is created with 7-day message retention and a storage policy pinning
messages to your `region`. The subscription gets a 600s ack deadline and a 10s
minimum retry backoff.

### `sink` (optional)

Archives **every message published to the topic** into a GCS bucket.

| Key | Description | Required | Default |
|---|---|---|---|
| `sink_name` | Bucket is created as `<project>-<sink_name>` | yes | — |
| `retention_days` | Exported files are **deleted** after this many days | no | `30` |
| `max_duration` | Start a new file after this long | no | `300s` |
| `max_bytes` | Start a new file after this many bytes | no | `10485760` |
| `filename_prefix` | Prefix for exported object names | no | `messages-` |

Two things to know:

> **`retention_days` silently deletes data.** The default drops exported
> messages after 30 days. Set it to match your actual retention obligations.

> **The sink creates a second subscription**, `<sink_name>-gcs-export`, separate
> from the one under `pubsub`. A subscription with a cloud-storage config is
> consumed by Pub/Sub itself and can't also be pulled from, so it can't share
> the pull subscription.

Earlier versions of this template created the sink bucket and nothing else — no
subscription ever wrote to it, so the bucket stayed empty. It now creates the
export subscription and grants the Pub/Sub service agent
`roles/storage.objectCreator` on the bucket.

## What you get

- the topic and its pull subscription
- a dedicated service account `<service_account_id>` with `pubsub.viewer` and
  `pubsub.subscriber` **on that subscription only**
- with a `sink`: a private, versionless bucket `<project>-<sink_name>` with a
  lifecycle rule, plus the export subscription

The bucket name is prefixed with your project because GCS bucket names live in
one global namespace — an unprefixed name like `example-sink` is almost
certainly already taken by someone else.
