# SageMaker Platform Module
# This module creates a comprehensive SageMaker infrastructure for MLOps

terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC and networking (if not provided)
data "aws_vpc" "existing" {
  count = var.vpc_id != "" ? 1 : 0
  id    = var.vpc_id
}

data "aws_subnets" "private" {
  count = var.vpc_id != "" ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    Type = "private"
  }
}

# SageMaker Studio Domain
resource "aws_sagemaker_domain" "studio" {
  domain_name = var.domain_name
  auth_mode   = "IAM"
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  default_user_settings {
    execution_role = aws_iam_role.sagemaker_execution.arn
    
    jupyter_server_app_settings {
      default_resource_spec {
        instance_type       = var.default_instance_type
        sagemaker_image_arn = var.sagemaker_image_arn
      }
    }
    
    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type       = var.default_instance_type
        sagemaker_image_arn = var.sagemaker_image_arn
      }
    }
    
    tensor_board_app_settings {
      default_resource_spec {
        instance_type = "ml.t3.medium"
      }
    }

    sharing_settings {
      notebook_output_option = "Allowed"
      s3_output_location     = "s3://${aws_s3_bucket.sagemaker_bucket.bucket}/studio-outputs/"
    }
  }

  default_space_settings {
    execution_role = aws_iam_role.sagemaker_execution.arn
    
    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = var.default_instance_type
      }
    }
    
    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = var.default_instance_type
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-sagemaker-domain"
  })
}

# SageMaker User Profiles
resource "aws_sagemaker_user_profile" "users" {
  for_each    = toset(var.user_profiles)
  domain_id   = aws_sagemaker_domain.studio.id
  user_profile_name = each.value

  user_settings {
    execution_role = aws_iam_role.sagemaker_execution.arn
    
    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = var.default_instance_type
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-user-${each.value}"
  })
}

# S3 Bucket for SageMaker artifacts
resource "aws_s3_bucket" "sagemaker_bucket" {
  bucket = "${var.project_name}-sagemaker-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-sagemaker-bucket"
  })
}

resource "aws_s3_bucket_versioning" "sagemaker_bucket_versioning" {
  bucket = aws_s3_bucket.sagemaker_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sagemaker_bucket_encryption" {
  bucket = aws_s3_bucket.sagemaker_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.sagemaker_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "sagemaker_bucket_pab" {
  bucket = aws_s3_bucket.sagemaker_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS Key for SageMaker encryption
resource "aws_kms_key" "sagemaker_key" {
  description             = "KMS key for SageMaker encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow SageMaker Service"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-sagemaker-key"
  })
}

resource "aws_kms_alias" "sagemaker_key_alias" {
  name          = "alias/${var.project_name}-sagemaker"
  target_key_id = aws_kms_key.sagemaker_key.key_id
}

# Model Registry (Model Package Groups)
resource "aws_sagemaker_model_package_group" "model_groups" {
  for_each                    = toset(var.model_package_groups)
  model_package_group_name    = each.value
  model_package_group_description = "Model package group for ${each.value} models"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.value}-model-group"
  })
}

# Feature Store (Feature Groups require additional setup via SDK/API)
# We'll create the necessary IAM roles and S3 buckets for Feature Store
resource "aws_s3_bucket" "feature_store_bucket" {
  bucket = "${var.project_name}-feature-store-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-feature-store-bucket"
  })
}

resource "aws_s3_bucket_versioning" "feature_store_versioning" {
  bucket = aws_s3_bucket.feature_store_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "feature_store_encryption" {
  bucket = aws_s3_bucket.feature_store_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.sagemaker_key.arn
    }
  }
}

# CloudWatch Log Groups for SageMaker
resource "aws_cloudwatch_log_group" "sagemaker_training" {
  name              = "/aws/sagemaker/TrainingJobs/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-training-logs"
  })
}

resource "aws_cloudwatch_log_group" "sagemaker_endpoints" {
  name              = "/aws/sagemaker/Endpoints/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-endpoint-logs"
  })
}

resource "aws_cloudwatch_log_group" "sagemaker_processing" {
  name              = "/aws/sagemaker/ProcessingJobs/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-processing-logs"
  })
}

# Model Monitor Resources
resource "aws_s3_bucket" "model_monitor_bucket" {
  bucket = "${var.project_name}-model-monitor-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-model-monitor-bucket"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "model_monitor_encryption" {
  bucket = aws_s3_bucket.model_monitor_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.sagemaker_key.arn
    }
  }
}

# EventBridge Rule for Model Monitoring
resource "aws_cloudwatch_event_rule" "model_monitor_rule" {
  name        = "${var.project_name}-model-monitor-rule"
  description = "Rule to trigger model monitoring jobs"

  event_pattern = jsonencode({
    source      = ["aws.sagemaker"]
    detail-type = ["SageMaker Model Monitor Execution Status Change"]
    detail = {
      MonitoringExecutionStatus = ["Failed", "Completed"]
    }
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-model-monitor-rule"
  })
}

# SNS Topic for Model Monitor Alerts
resource "aws_sns_topic" "model_monitor_alerts" {
  name = "${var.project_name}-model-monitor-alerts"

  tags = merge(var.tags, {
    Name = "${var.project_name}-model-monitor-alerts"
  })
}

# Lambda function for processing model monitor alerts (placeholder)
resource "aws_lambda_function" "model_monitor_processor" {
  count = var.enable_model_monitoring ? 1 : 0
  
  filename         = "model_monitor_lambda.zip"
  function_name    = "${var.project_name}-model-monitor-processor"
  role            = aws_iam_role.lambda_execution[0].arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  source_code_hash = data.archive_file.model_monitor_lambda[0].output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.model_monitor_alerts.arn
      PROJECT_NAME  = var.project_name
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-model-monitor-processor"
  })
}

# Lambda deployment package
data "archive_file" "model_monitor_lambda" {
  count = var.enable_model_monitoring ? 1 : 0
  
  type        = "zip"
  output_path = "model_monitor_lambda.zip"
  
  source {
    content = <<EOF
import json
import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns = boto3.client('sns')

def handler(event, context):
    """
    Process SageMaker Model Monitor alerts
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Extract monitoring execution details
        detail = event.get('detail', {})
        execution_status = detail.get('MonitoringExecutionStatus')
        execution_arn = detail.get('MonitoringExecutionArn')
        
        # Create alert message
        message = f"""
        SageMaker Model Monitor Alert
        
        Status: {execution_status}
        Execution ARN: {execution_arn}
        Time: {event.get('time')}
        
        Please check the SageMaker console for detailed results.
        """
        
        # Send SNS notification
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject=f"Model Monitor Alert - {execution_status}",
            Message=message
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps('Alert processed successfully')
        }
        
    except Exception as e:
        logger.error(f"Error processing alert: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
EOF
    filename = "index.py"
  }
}

# EventBridge Target for Lambda
resource "aws_cloudwatch_event_target" "model_monitor_lambda_target" {
  count = var.enable_model_monitoring ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.model_monitor_rule.name
  target_id = "ModelMonitorLambdaTarget"
  arn       = aws_lambda_function.model_monitor_processor[0].arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  count = var.enable_model_monitoring ? 1 : 0
  
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.model_monitor_processor[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.model_monitor_rule.arn
}
