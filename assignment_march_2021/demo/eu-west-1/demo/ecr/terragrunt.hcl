# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}


locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  # common_vars = yamldecode(file(find_in_parent_folders("common_vars.yaml")))
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  # env    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # Extract the variables we need for easy access
  account_name = local.account.locals.account_name
  account_id   = local.account.locals.aws_account_id
  aws_region   = local.region.locals.aws_region
  
  namespace    = "${local.env.locals.environment}-${local.env.locals.environment}"

  cluster_name = "${local.env.locals.environment}-${local.env.locals.environment}"
  environment  = local.env.locals.environment

  }


dependency "vpc" {
  config_path = "${get_parent_terragrunt_dir()}/${local.account_name}/${local.aws_region}/${local.account_name}/vpc"
  mock_outputs = {
    vpc_id = "temporary-dummy-id"
    private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]

  }
}



terraform {
  source  = "github.com/cloudposse/terraform-aws-ecr"
}


inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  enabled = true
  name = "test"
  use_fullname = false
  principals_full_access = ["*"]
}
