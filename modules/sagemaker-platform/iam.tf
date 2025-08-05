# IAM Roles and Policies for SageMaker Platform

# SageMaker Execution Role
resource "aws_iam_role" "sagemaker_execution" {
  name = "${var.project_name}-sagemaker-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-sagemaker-execution-role"
  })
}

# Attach AWS managed policy for SageMaker execution
resource "aws_iam_role_policy_attachment" "sagemaker_execution_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
  role       = aws_iam_role.sagemaker_execution.name
}

# Custom policy for SageMaker execution with specific permissions
resource "aws_iam_role_policy" "sagemaker_execution_custom" {
  name = "${var.project_name}-sagemaker-execution-custom"
  role = aws_iam_role.sagemaker_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.sagemaker_bucket.arn,
          "${aws_s3_bucket.sagemaker_bucket.arn}/*",
          aws_s3_bucket.feature_store_bucket.arn,
          "${aws_s3_bucket.feature_store_bucket.arn}/*",
          aws_s3_bucket.model_monitor_bucket.arn,
          "${aws_s3_bucket.model_monitor_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [aws_kms_key.sagemaker_key.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          aws_cloudwatch_log_group.sagemaker_training.arn,
          aws_cloudwatch_log_group.sagemaker_endpoints.arn,
          aws_cloudwatch_log_group.sagemaker_processing.arn,
          "${aws_cloudwatch_log_group.sagemaker_training.arn}:*",
          "${aws_cloudwatch_log_group.sagemaker_endpoints.arn}:*",
          "${aws_cloudwatch_log_group.sagemaker_processing.arn}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [aws_sns_topic.model_monitor_alerts.arn]
      }
    ]
  })
}

# SageMaker Feature Store Execution Role
resource "aws_iam_role" "feature_store_execution" {
  name = "${var.project_name}-feature-store-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["sagemaker.amazonaws.com", "glue.amazonaws.com"]
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-feature-store-execution-role"
  })
}

# Feature Store execution policy
resource "aws_iam_role_policy" "feature_store_execution" {
  name = "${var.project_name}-feature-store-execution"
  role = aws_iam_role.feature_store_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.feature_store_bucket.arn,
          "${aws_s3_bucket.feature_store_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:CreateDatabase",
          "glue:CreateTable",
          "glue:UpdateTable",
          "glue:DeleteTable",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchCreatePartition",
          "glue:BatchDeletePartition",
          "glue:BatchUpdatePartition"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [aws_kms_key.sagemaker_key.arn]
      }
    ]
  })
}

# Lambda execution role for model monitoring
resource "aws_iam_role" "lambda_execution" {
  count = var.enable_model_monitoring ? 1 : 0
  name  = "${var.project_name}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-lambda-execution-role"
  })
}

# Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count      = var.enable_model_monitoring ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution[0].name
}

resource "aws_iam_role_policy" "lambda_sns_publish" {
  count = var.enable_model_monitoring ? 1 : 0
  name  = "${var.project_name}-lambda-sns-publish"
  role  = aws_iam_role.lambda_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [aws_sns_topic.model_monitor_alerts.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "sagemaker:DescribeMonitoringSchedule",
          "sagemaker:DescribeProcessingJob",
          "sagemaker:ListMonitoringExecutions"
        ]
        Resource = "*"
      }
    ]
  })
}

# Step Functions execution role for ML pipelines
resource "aws_iam_role" "step_functions_execution" {
  name = "${var.project_name}-step-functions-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-step-functions-execution-role"
  })
}

# Step Functions execution policy
resource "aws_iam_role_policy" "step_functions_execution" {
  name = "${var.project_name}-step-functions-execution"
  role = aws_iam_role.step_functions_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:StopTrainingJob",
          "sagemaker:CreateProcessingJob",
          "sagemaker:DescribeProcessingJob",
          "sagemaker:StopProcessingJob",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateEndpoint",
          "sagemaker:DescribeEndpoint",
          "sagemaker:InvokeEndpoint",
          "sagemaker:UpdateEndpoint",
          "sagemaker:DeleteEndpoint",
          "sagemaker:DeleteEndpointConfig",
          "sagemaker:DeleteModel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.sagemaker_execution.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ]
        Resource = "*"
      }
    ]
  })
}

# SageMaker Pipeline execution role
resource "aws_iam_role" "pipeline_execution" {
  name = "${var.project_name}-pipeline-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-pipeline-execution-role"
  })
}

# SageMaker Pipeline execution policy
resource "aws_iam_role_policy" "pipeline_execution" {
  name = "${var.project_name}-pipeline-execution"
  role = aws_iam_role.pipeline_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:CreateProcessingJob",
          "sagemaker:CreateModel",
          "sagemaker:CreateModelPackage",
          "sagemaker:DescribeTrainingJob",
          "sagemaker:DescribeProcessingJob",
          "sagemaker:DescribeModel",
          "sagemaker:DescribeModelPackage",
          "sagemaker:UpdateModelPackage",
          "sagemaker:ListModelPackages"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.sagemaker_bucket.arn,
          "${aws_s3_bucket.sagemaker_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.sagemaker_execution.arn
        ]
      }
    ]
  })
}
