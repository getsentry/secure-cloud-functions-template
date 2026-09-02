plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "google" {
  enabled = true
  version = "0.36.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

# The loader modules (functions/, workflows/, pubsubs/) declare untyped
# variables on purpose -- they pass straight through to the real modules, which
# do the type checking. Documenting them twice adds drift, not safety.
rule "terraform_documented_variables" {
  enabled = false
}

rule "terraform_typed_variables" {
  enabled = false
}
