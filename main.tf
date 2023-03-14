terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.58"
    }
  }
}

provider "aws" {}

data "aws_region" "main" {}

locals {
  region = data.aws_region.main.name
}

// https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/3.19.0
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "demo"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
}

module "eks_cluster" {
  source = "./modules/eks_cluster"

  cluster_name       = "demo"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
}
