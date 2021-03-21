# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}


locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # Extract the variables we need for easy access
  account_name = local.account.locals.account_name
  account_id   = local.account.locals.aws_account_id
  aws_region   = local.region.locals.aws_region
  
  namespace    = "${local.env.locals.environment}-${local.env.locals.environment}"

  cluster_name = "eks-${local.env.locals.environment}"

  }



terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-vpc//?ref=v2.47.0"
}

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

inputs = {
  name                 = "test-vpc"
  cidr                 = "172.16.0.0/16"
  azs                  = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}