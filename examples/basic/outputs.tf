output "sagemaker_domain_id" {
  description = "ID of the SageMaker Studio Domain."
  value       = module.sagemaker_platform.sagemaker_domain_id
}

output "sagemaker_domain_url" {
  description = "URL of the SageMaker Studio Domain."
  value       = module.sagemaker_platform.sagemaker_domain_url
}

output "sagemaker_bucket_name" {
  description = "Name of the S3 bucket for SageMaker artifacts."
  value       = module.sagemaker_platform.sagemaker_bucket_name
}

output "feature_store_bucket_name" {
  description = "Name of the S3 bucket backing the Feature Store offline store."
  value       = module.sagemaker_platform.feature_store_bucket_name
}

output "sagemaker_kms_key_arn" {
  description = "ARN of the KMS key encrypting SageMaker resources."
  value       = module.sagemaker_platform.sagemaker_kms_key_arn
}

output "sagemaker_execution_role_arn" {
  description = "ARN of the SageMaker execution role."
  value       = module.sagemaker_platform.sagemaker_execution_role_arn
}

output "model_monitor_alerts_topic_arn" {
  description = "SNS topic ARN that receives Model Monitor alerts."
  value       = module.sagemaker_platform.model_monitor_alerts_topic_arn
}
