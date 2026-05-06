# Basic example: deploys the sagemaker-platform module against an existing VPC.
#
# Prerequisites:
#   - An AWS account and credentials available to the AWS provider
#   - An existing VPC with at least two private subnets
#
# Usage:
#   terraform init
#   terraform plan -var="vpc_id=vpc-xxx" -var='subnet_ids=["subnet-a","subnet-b"]'
#   terraform apply

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
  default     = "ml-demo"
}

variable "vpc_id" {
  description = "Existing VPC ID where SageMaker Studio will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Two or more private subnet IDs in the VPC above."
  type        = list(string)
}

module "sagemaker_platform" {
  source = "../../modules/sagemaker-platform"

  project_name = var.project_name
  domain_name  = "${var.project_name}-studio"
  environment  = "dev"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  default_instance_type = "ml.t3.medium"
  user_profiles         = ["data-scientist", "ml-engineer"]
  model_package_groups  = ["classification-models"]

  enable_model_monitoring = true
  log_retention_days      = 30

  tags = {
    Owner       = "platform"
    Environment = "dev"
  }
}
