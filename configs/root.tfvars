# This is a terraform configuration file

# The "apex" service discovery domain for *all* infrastructure
domain = "union-pos.net"

# The global namespace that should be shared by all accounts
namespace = "up"

# The default region for this account
aws_region = "us-west-2"

# Network CIDR of Organization
org_network_cidr    = "10.0.0.0/8"
org_network_offset  = 100
org_network_newbits = 8 # /8 + /8 = /16

# Pod IP address space (must not overlap with org_network_cidr)
# 100.64.0.0/10 is the default used by kops, even though it is technically reserved for carrier-grade NAT
# See https://github.com/cloudposse/docs/issues/455
kops_non_masquerade_cidr = "100.64.0.0/10"


# The docker registry that will be used for the images built (nothing will get pushed)
docker_registry = "unionpos"

# define the list of templates which will be included in the geodesic image
templates = [
  "README.md",
  "Dockerfile.root",
  ".github/CODEOWNERS",
  ".github/ISSUE_TEMPLATE/feature-request.md",
  ".github/ISSUE_TEMPLATE/bug.md",
  ".github/PULL_REQUEST.md",
  ".editorconfig",
  ".gitignore",
  ".dockerignore",
  "Makefile",
  "conf/accounts/.envrc",
  "conf/accounts/Makefile.tasks",
  "conf/accounts/terraform.envrc",
  "conf/accounts/terraform.tfvars",
  "conf/account-settings/.envrc",
  "conf/account-settings/Makefile.tasks",
  "conf/account-settings/terraform.envrc",
  "conf/account-settings/terraform.tfvars",
  "conf/bootstrap/.envrc",
  "conf/bootstrap/Makefile.tasks",
  "conf/bootstrap/terraform.envrc",
  "conf/bootstrap/terraform.tfvars",
  "conf/cloudtrail/.envrc",
  "conf/cloudtrail/Makefile.tasks",
  "conf/cloudtrail/terraform.envrc",
  "conf/iam/.envrc",
  "conf/iam/Makefile.tasks",
  "conf/iam/terraform.envrc",
  "conf/iam/terraform.tfvars",
  "conf/root-dns/.envrc",
  "conf/root-dns/Makefile.tasks",
  "conf/root-dns/terraform.envrc",
  "conf/root-dns/terraform.tfvars",
  "conf/root-iam/.envrc",
  "conf/root-iam/Makefile.tasks",
  "conf/root-iam/terraform.envrc",
  "conf/tfstate-backend/.envrc",
  "conf/tfstate-backend/Makefile.tasks",
  "conf/tfstate-backend/terraform.envrc",
  "conf/tfstate-backend/terraform.tfvars",
  "conf/users/.envrc",
  "conf/users/Makefile.tasks",
  "conf/users/terraform.envrc",
  "conf/users/terraform.tfvars"
]

# Account email address format (e.g. `ops+%s@example.co`). This is not easily changed later.
account_email = "devops+%s@union-pos.com"

# List of accounts to enable
accounts_enabled = [
  "dev",
  "staging",
  "prod",
  "testing",
  # "data",
  "corp",
  "audit",
  "security",
  "identity",
]

# Administrator IAM usernames mapped to their keybase usernames for password encryption
users = {
  "russell@union-pos.com" = "russellunionpos"
}

# Geodesic Base Image (don't change this unless you know what you're doing)
# Project: https://github.com/cloudposse/geodesic
geodesic_base_image = "cloudposse/geodesic:0.115.0"

# List of terraform root modules to apply during provisioning
terraform_root_modules = [
  "aws/tfstate-backend",
  "aws/accounts",
  "aws/account-settings",
  "aws/bootstrap",
  # "aws/root-dns",
  "aws/root-iam",
  "aws/iam",
  "aws/users",
  "aws/cloudtrail",
]

# Message of the Day
motd_url = "https://geodesic.sh/motd"
