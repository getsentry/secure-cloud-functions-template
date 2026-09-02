# Read by the build step in .github/workflows/terraform-apply.yaml so it knows
# which images to build and push before applying.
output "images" {
  description = "Map of service directory to the container image it deploys."
  value       = local.images
}

output "service_urls" {
  description = "Map of service name to its Cloud Run URL."
  value       = { for k, m in module.cloud_run : k => m.service_url }
}
