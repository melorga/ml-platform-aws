# Outputs for SageMaker Platform Module

# SageMaker Studio Domain outputs
output "sagemaker_domain_id" {
  description = "ID of the SageMaker Studio Domain"
  value       = aws_sagemaker_domain.studio.id
}

output "sagemaker_domain_arn" {
  description = "ARN of the SageMaker Studio Domain"
  value       = aws_sagemaker_domain.studio.arn
}

output "sagemaker_domain_url" {
  description = "URL of the SageMaker Studio Domain"
  value       = aws_sagemaker_domain.studio.url
}

# User profiles outputs
output "user_profiles" {
  description = "Map of user profile names to their ARNs"
  value = {
    for k, v in aws_sagemaker_user_profile.users : k => v.arn
  }
}

# S3 Bucket outputs
output "sagemaker_bucket_name" {
  description = "Name of the S3 bucket for SageMaker artifacts"
  value       = aws_s3_bucket.sagemaker_bucket.bucket
}

output "sagemaker_bucket_arn" {
  description = "ARN of the S3 bucket for SageMaker artifacts"
  value       = aws_s3_bucket.sagemaker_bucket.arn
}

output "feature_store_bucket_name" {
  description = "Name of the S3 bucket for Feature Store"
  value       = aws_s3_bucket.feature_store_bucket.bucket
}

output "feature_store_bucket_arn" {
  description = "ARN of the S3 bucket for Feature Store"
  value       = aws_s3_bucket.feature_store_bucket.arn
}

output "model_monitor_bucket_name" {
  description = "Name of the S3 bucket for Model Monitor"
  value       = aws_s3_bucket.model_monitor_bucket.bucket
}

output "model_monitor_bucket_arn" {
  description = "ARN of the S3 bucket for Model Monitor"
  value       = aws_s3_bucket.model_monitor_bucket.arn
}

# KMS Key outputs
output "sagemaker_kms_key_id" {
  description = "ID of the KMS key used for SageMaker encryption"
  value       = aws_kms_key.sagemaker_key.key_id
}

output "sagemaker_kms_key_arn" {
  description = "ARN of the KMS key used for SageMaker encryption"
  value       = aws_kms_key.sagemaker_key.arn
}

output "sagemaker_kms_alias_name" {
  description = "Alias name of the KMS key used for SageMaker encryption"
  value       = aws_kms_alias.sagemaker_key_alias.name
}

# Model Registry outputs
output "model_package_groups" {
  description = "Map of model package group names to their ARNs"
  value = {
    for k, v in aws_sagemaker_model_package_group.model_groups : k => v.arn
  }
}

# IAM Role outputs
output "sagemaker_execution_role_arn" {
  description = "ARN of the SageMaker execution role"
  value       = aws_iam_role.sagemaker_execution.arn
}

output "sagemaker_execution_role_name" {
  description = "Name of the SageMaker execution role"
  value       = aws_iam_role.sagemaker_execution.name
}

output "feature_store_execution_role_arn" {
  description = "ARN of the Feature Store execution role"
  value       = aws_iam_role.feature_store_execution.arn
}

output "step_functions_execution_role_arn" {
  description = "ARN of the Step Functions execution role"
  value       = aws_iam_role.step_functions_execution.arn
}

output "pipeline_execution_role_arn" {
  description = "ARN of the SageMaker Pipeline execution role"
  value       = aws_iam_role.pipeline_execution.arn
}

# CloudWatch Log Groups outputs
output "training_log_group_name" {
  description = "Name of the CloudWatch log group for training jobs"
  value       = aws_cloudwatch_log_group.sagemaker_training.name
}

output "endpoints_log_group_name" {
  description = "Name of the CloudWatch log group for endpoints"
  value       = aws_cloudwatch_log_group.sagemaker_endpoints.name
}

output "processing_log_group_name" {
  description = "Name of the CloudWatch log group for processing jobs"
  value       = aws_cloudwatch_log_group.sagemaker_processing.name
}

# Model Monitoring outputs
output "model_monitor_alerts_topic_arn" {
  description = "ARN of the SNS topic for model monitor alerts"
  value       = aws_sns_topic.model_monitor_alerts.arn
}

output "model_monitor_rule_arn" {
  description = "ARN of the EventBridge rule for model monitoring"
  value       = aws_cloudwatch_event_rule.model_monitor_rule.arn
}

output "model_monitor_lambda_function_arn" {
  description = "ARN of the Lambda function for processing model monitor alerts"
  value       = var.enable_model_monitoring ? aws_lambda_function.model_monitor_processor[0].arn : null
}

# Configuration outputs for use by other modules
output "sagemaker_config" {
  description = "SageMaker configuration for use by other modules"
  value = {
    domain_id              = aws_sagemaker_domain.studio.id
    domain_name           = aws_sagemaker_domain.studio.domain_name
    execution_role_arn    = aws_iam_role.sagemaker_execution.arn
    s3_bucket            = aws_s3_bucket.sagemaker_bucket.bucket
    kms_key_id           = aws_kms_key.sagemaker_key.key_id
    vpc_id               = var.vpc_id
    subnet_ids           = var.subnet_ids
  }
}

output "monitoring_config" {
  description = "Model monitoring configuration for use by other modules"
  value = {
    enabled                = var.enable_model_monitoring
    s3_bucket             = aws_s3_bucket.model_monitor_bucket.bucket
    sns_topic_arn         = aws_sns_topic.model_monitor_alerts.arn
    eventbridge_rule_arn  = aws_cloudwatch_event_rule.model_monitor_rule.arn
    lambda_function_arn   = var.enable_model_monitoring ? aws_lambda_function.model_monitor_processor[0].arn : null
  }
}

# Resource counts for validation
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    user_profiles_count        = length(aws_sagemaker_user_profile.users)
    model_package_groups_count = length(aws_sagemaker_model_package_group.model_groups)
    s3_buckets_count          = 3  # sagemaker_bucket, feature_store_bucket, model_monitor_bucket
    iam_roles_count           = var.enable_model_monitoring ? 5 : 4
    log_groups_count          = 3  # training, endpoints, processing
  }
}
