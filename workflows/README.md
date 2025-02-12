# GCP Cloud Workflows

This Terraform module helps deploy and manage Google Cloud Workflows.

Terraform definitions will be pulled from the `terraform.yaml` file under each folders in `.workflows`

## Usage
```yaml
name: example1
description: example workflow
functions:
  - example-gen2
  - example-gen2-cron
workflow-trigger:
  criteria:
    - attribute: type
      value: google.cloud.pubsub.topic.v1.messagePublished
```

## Inputs
### Basic Info
| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | Name of the Workflow | string | yes | - |
| description | Description of the Workflow | string | no | null |
| functions | List of functions in the workflow | list(string) | no | - |

### Workflow Eventarc Trigger
| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| workflow-trigger | Name of the workflow trigger | string | yes | - |
| criteria | The list of filters that applies to event attributes | list(map) | yes | - |

## How to Create a New Workflow

1. Create a new folder under `./workflows/` with your workflow name as the folder name
2. Create the `workflow.yaml` file in your folder with your workflow definitions
3. Create the `terraform.yaml` file in your folder, provide required information based on the [Usage](#usage) and [Input](#inputs)
    - Ensure all the functions you have in your `workflow.yaml` is listed in the `functions` list in your `terraform.yaml`, without it your workflow won't be granted with proper permissions to the functions
4. Create a ReadMe.md in your folder to provide context on your workflow setup
