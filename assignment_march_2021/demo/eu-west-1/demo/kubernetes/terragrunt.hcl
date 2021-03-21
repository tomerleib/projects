include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-eks.git//?ref=v13.2.1"

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output kubeconfig 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }


}

locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  env     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  
  # Extract the variables we need for easy access
  account_name = local.account.locals.account_name
  account_id   = local.account.locals.aws_account_id
  aws_region   = local.region.locals.aws_region

  cluster_name = "eks-${local.env.locals.environment}"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000"
    private_subnets = [
      "subnet-00000000",
      "subnet-00000001",
      "subnet-00000002",
    ]
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"
      profile = "
    }
    provider "kubernetes" {
      version = ">= 2.0"
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      token                  = data.aws_eks_cluster_auth.cluster.token

      
    }
    data "aws_eks_cluster" "cluster" {
      name = aws_eks_cluster.this[0].id
    }
    data "aws_eks_cluster_auth" "cluster" {
      name = aws_eks_cluster.this[0].id
    }
  EOF
}

inputs = {

  aws = {
    "region" = local.aws_region
  }



  cluster_name                         = local.cluster_name
  subnets                              = dependency.vpc.outputs.private_subnets
  vpc_id                               = dependency.vpc.outputs.vpc_id
  write_kubeconfig                     = true
  enable_irsa                          = true
  kubeconfig_aws_authenticator_command = "aws"
  kubeconfig_aws_authenticator_command_args = [
    "eks",
    "get-token",
    "--cluster-name",
    local.cluster_name
  ]
  kubeconfig_aws_authenticator_additional_args = []

  cluster_version           = "1.18"
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  node_groups = {
    "default-${local.aws_region}a" = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3a.medium"
      subnets          = [dependency.vpc.outputs.private_subnets[0]]
      disk_size        = 50
    }

    "default-${local.aws_region}b" = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3a.medium"
      subnets          = [dependency.vpc.outputs.private_subnets[1]]
      disk_size        = 50
    }

    "default-${local.aws_region}c" = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3a.medium"
      subnets          = [dependency.vpc.outputs.private_subnets[2]]
      disk_size        = 50
    }
  }
}