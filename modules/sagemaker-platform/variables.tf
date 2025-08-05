# Variables for SageMaker Platform Module

variable "project_name" {
  description = "Name of the project. Used for resource naming and tagging."
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.project_name))
    error_message = "Project name must start with a letter, contain only alphanumeric characters and hyphens, and end with an alphanumeric character."
  }
}

variable "domain_name" {
  description = "Name for the SageMaker Studio Domain"
  type        = string
  default     = ""
  
  validation {
    condition     = var.domain_name == "" || can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.domain_name))
    error_message = "Domain name must start with a letter, contain only alphanumeric characters and hyphens, and end with an alphanumeric character."
  }
}

variable "vpc_id" {
  description = "VPC ID where SageMaker Studio will be deployed"
  type        = string
  
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for SageMaker Studio (should be private subnets)"
  type        = list(string)
  
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs must be provided for high availability."
  }
  
  validation {
    condition     = alltrue([for s in var.subnet_ids : can(regex("^subnet-[a-z0-9]+$", s))])
    error_message = "All subnet IDs must be valid AWS subnet identifiers."
  }
}

variable "default_instance_type" {
  description = "Default instance type for SageMaker Studio apps"
  type        = string
  default     = "ml.t3.medium"
  
  validation {
    condition = contains([
      "ml.t3.medium", "ml.t3.large", "ml.t3.xlarge", "ml.t3.2xlarge",
      "ml.m5.large", "ml.m5.xlarge", "ml.m5.2xlarge", "ml.m5.4xlarge",
      "ml.c5.large", "ml.c5.xlarge", "ml.c5.2xlarge", "ml.c5.4xlarge"
    ], var.default_instance_type)
    error_message = "Instance type must be a valid SageMaker instance type."
  }
}

variable "sagemaker_image_arn" {
  description = "ARN of the SageMaker image to use for Studio apps"
  type        = string
  default     = null
}

variable "user_profiles" {
  description = "List of user profiles to create in SageMaker Studio"
  type        = list(string)
  default     = ["data-scientist", "ml-engineer"]
  
  validation {
    condition     = length(var.user_profiles) > 0
    error_message = "At least one user profile must be specified."
  }
  
  validation {
    condition     = alltrue([for p in var.user_profiles : can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", p))])
    error_message = "User profile names must start with a letter, contain only alphanumeric characters and hyphens, and end with an alphanumeric character."
  }
}

variable "model_package_groups" {
  description = "List of model package groups to create for the model registry"
  type        = list(string)
  default     = ["classification-models", "regression-models", "nlp-models"]
  
  validation {
    condition     = length(var.model_package_groups) > 0
    error_message = "At least one model package group must be specified."
  }
  
  validation {
    condition     = alltrue([for g in var.model_package_groups : can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", g))])
    error_message = "Model package group names must start with a letter, contain only alphanumeric characters and hyphens, and end with an alphanumeric character."
  }
}

variable "enable_model_monitoring" {
  description = "Enable model monitoring with automated alerting"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch log retention period."
  }
}

variable "enable_feature_store" {
  description = "Enable SageMaker Feature Store resources"
  type        = bool
  default     = true
}

variable "feature_store_s3_prefix" {
  description = "S3 prefix for Feature Store offline store"
  type        = string
  default     = "feature-store"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9/_-]+$", var.feature_store_s3_prefix))
    error_message = "S3 prefix must contain only alphanumeric characters, hyphens, underscores, and forward slashes."
  }
}

variable "training_instance_types" {
  description = "List of allowed instance types for training jobs"
  type        = list(string)
  default = [
    "ml.m5.large", "ml.m5.xlarge", "ml.m5.2xlarge", "ml.m5.4xlarge",
    "ml.c5.xlarge", "ml.c5.2xlarge", "ml.c5.4xlarge",
    "ml.p3.2xlarge", "ml.p3.8xlarge"
  ]
}

variable "endpoint_instance_types" {
  description = "List of allowed instance types for model endpoints"
  type        = list(string)
  default = [
    "ml.t2.medium", "ml.t2.large", "ml.t2.xlarge",
    "ml.m5.large", "ml.m5.xlarge", "ml.m5.2xlarge",
    "ml.c5.large", "ml.c5.xlarge", "ml.c5.2xlarge"
  ]
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for SageMaker endpoints"
  type        = bool
  default     = true
}

variable "max_capacity" {
  description = "Maximum capacity for auto-scaling endpoints"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_capacity >= 1 && var.max_capacity <= 100
    error_message = "Maximum capacity must be between 1 and 100."
  }
}

variable "min_capacity" {
  description = "Minimum capacity for auto-scaling endpoints"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_capacity >= 1 && var.min_capacity <= 100
    error_message = "Minimum capacity must be between 1 and 100."
  }
}

variable "target_tracking_scaling_policy_configuration" {
  description = "Configuration for target tracking scaling policy"
  type = object({
    target_value               = number
    predefined_metric_type     = string
    scale_out_cooldown        = number
    scale_in_cooldown         = number
  })
  default = {
    target_value               = 70.0
    predefined_metric_type     = "SageMakerVariantInvocationsPerInstance"
    scale_out_cooldown        = 300
    scale_in_cooldown         = 300
  }
}

variable "notification_email" {
  description = "Email address for model monitoring notifications"
  type        = string
  default     = ""
  
  validation {
    condition     = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Notification email must be a valid email address."
  }
}

variable "enable_data_capture" {
  description = "Enable data capture for model endpoints"
  type        = bool
  default     = true
}

variable "data_capture_percentage" {
  description = "Percentage of requests to capture for model monitoring"
  type        = number
  default     = 100
  
  validation {
    condition     = var.data_capture_percentage >= 0 && var.data_capture_percentage <= 100
    error_message = "Data capture percentage must be between 0 and 100."
  }
}

variable "model_approval_status" {
  description = "Default approval status for models in the registry"
  type        = string
  default     = "PendingManualApproval"
  
  validation {
    condition     = contains(["Approved", "Rejected", "PendingManualApproval"], var.model_approval_status)
    error_message = "Model approval status must be one of: Approved, Rejected, PendingManualApproval."
  }
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition     = alltrue([for k, v in var.tags : can(regex("^[a-zA-Z0-9\\s_.:/=+\\-@]*$", k)) && can(regex("^[a-zA-Z0-9\\s_.:/=+\\-@]*$", v))])
    error_message = "Tag keys and values must contain only alphanumeric characters, spaces, and the characters _.:/=+-@"
  }
}
