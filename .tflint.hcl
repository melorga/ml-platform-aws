config {
  call_module_type = "all"
  force            = false
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.47.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Module variables form the public interface of the module and may be
# consumed by callers (or wired up incrementally). Disable this rule so
# that declared-but-not-yet-used inputs do not fail CI.
rule "terraform_unused_declarations" {
  enabled = false
}
