locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  
  # Extract the variables we need for easy access
  # project      = local.proj.locals.project
  account_name = local.account.locals.account_name
  account_id   = local.account.locals.aws_account_id
  user         = local.account.locals.user_name
  aws_region   = local.region.locals.aws_region
}


# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  local.account.locals,
  local.region.locals,
  local.env.locals,
)


# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
    version = "~> 3.6.0"  

  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}

EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"

  config = {
    # Keep all statefiles in the scr-infra account
    # role_arn      = "arn:aws:iam::${local.account_id}:role/ops"
    encrypt        = true
    bucket         = "tomerl-terragrunt-state-demo"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = "terraform-locks"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
