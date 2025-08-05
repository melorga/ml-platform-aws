# SageMaker Platform Module

This Terraform module creates a comprehensive Amazon SageMaker platform for MLOps, including SageMaker Studio, Feature Store infrastructure, Model Registry, and monitoring capabilities.

## Features

- 🏗️ **SageMaker Studio Domain** with user profiles and custom configurations
- 📊 **Model Registry** with versioned model package groups
- 🗄️ **Feature Store** infrastructure (S3 buckets and IAM roles)
- 📈 **Model Monitoring** with automated alerting via EventBridge and SNS
- 🔐 **Security** with KMS encryption and least-privilege IAM roles
- 📝 **Logging** with structured CloudWatch log groups
- 🚀 **Auto-scaling** support for model endpoints

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SageMaker     │    │   Feature       │    │   Model         │
│   Studio        │    │   Store         │    │   Registry      │
│   Domain        │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────────────────────────────────────┐
         │               S3 Buckets                        │
         │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
         │  │ SageMaker   │ │ Feature     │ │ Model       │ │
         │  │ Artifacts   │ │ Store       │ │ Monitor     │ │
         │  └─────────────┘ └─────────────┘ └─────────────┘ │
         └─────────────────────────────────────────────────┘
                                 │
         ┌─────────────────────────────────────────────────┐
         │               Monitoring                        │
         │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
         │  │ EventBridge │ │ SNS Topic   │ │ Lambda      │ │
         │  │ Rules       │ │ Alerts      │ │ Processor   │ │
         │  └─────────────┘ └─────────────┘ └─────────────┘ │
         └─────────────────────────────────────────────────┘
```

## Usage

### Basic Usage

```hcl
module "sagemaker_platform" {
  source = "../../modules/sagemaker-platform"

  project_name = "my-ml-project"
  domain_name  = "my-ml-domain"
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345678", "subnet-87654321"]

  user_profiles = [
    "data-scientist-1",
    "data-scientist-2",
    "ml-engineer"
  ]

  model_package_groups = [
    "classification-models",
    "regression-models",
    "nlp-models"
  ]

  tags = {
    Environment = "prod"
    Team        = "ml-team"
    Project     = "ml-platform"
  }
}
```

### Advanced Usage with Custom Configuration

```hcl
module "sagemaker_platform" {
  source = "../../modules/sagemaker-platform"

  project_name = "advanced-ml-project"
  domain_name  = "advanced-ml-domain"
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345678", "subnet-87654321"]

  # Custom instance types
  default_instance_type = "ml.m5.large"
  
  # Enable advanced features
  enable_model_monitoring = true
  enable_feature_store    = true
  enable_auto_scaling     = true
  
  # Monitoring configuration
  notification_email      = "ml-team@company.com"
  data_capture_percentage = 50
  
  # Scaling configuration
  min_capacity = 2
  max_capacity = 20
  
  target_tracking_scaling_policy_configuration = {
    target_value               = 80.0
    predefined_metric_type     = "SageMakerVariantInvocationsPerInstance"
    scale_out_cooldown        = 180
    scale_in_cooldown         = 180
  }

  # Custom retention
  log_retention_days = 90

  tags = {
    Environment = "prod"
    Team        = "ml-team"
    Project     = "advanced-ml-platform"
    CostCenter  = "engineering"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Resources Created

### Core SageMaker Resources
- `aws_sagemaker_domain` - SageMaker Studio Domain
- `aws_sagemaker_user_profile` - User profiles for Studio access
- `aws_sagemaker_model_package_group` - Model registry groups

### Storage Resources
- `aws_s3_bucket` - SageMaker artifacts bucket
- `aws_s3_bucket` - Feature Store offline store bucket
- `aws_s3_bucket` - Model monitoring results bucket

### Security Resources
- `aws_kms_key` - KMS key for encryption
- `aws_iam_role` - SageMaker execution role
- `aws_iam_role` - Feature Store execution role
- `aws_iam_role` - Step Functions execution role
- `aws_iam_role` - Pipeline execution role
- `aws_iam_role` - Lambda execution role (if monitoring enabled)

### Monitoring Resources
- `aws_cloudwatch_log_group` - Training jobs logs
- `aws_cloudwatch_log_group` - Endpoint logs
- `aws_cloudwatch_log_group` - Processing jobs logs
- `aws_cloudwatch_event_rule` - Model monitoring events
- `aws_sns_topic` - Alert notifications
- `aws_lambda_function` - Monitoring alert processor (optional)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| vpc_id | VPC ID for SageMaker Studio | `string` | n/a | yes |
| subnet_ids | List of subnet IDs (minimum 2) | `list(string)` | n/a | yes |
| domain_name | SageMaker Studio domain name | `string` | `""` | no |
| default_instance_type | Default instance type for Studio apps | `string` | `"ml.t3.medium"` | no |
| user_profiles | List of user profiles to create | `list(string)` | `["data-scientist", "ml-engineer"]` | no |
| model_package_groups | List of model package groups | `list(string)` | `["classification-models", "regression-models", "nlp-models"]` | no |
| enable_model_monitoring | Enable model monitoring | `bool` | `true` | no |
| enable_feature_store | Enable Feature Store resources | `bool` | `true` | no |
| enable_auto_scaling | Enable auto-scaling for endpoints | `bool` | `true` | no |
| log_retention_days | CloudWatch log retention days | `number` | `30` | no |
| notification_email | Email for monitoring alerts | `string` | `""` | no |
| tags | Map of tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| sagemaker_domain_id | SageMaker Studio Domain ID |
| sagemaker_domain_arn | SageMaker Studio Domain ARN |
| sagemaker_domain_url | SageMaker Studio Domain URL |
| sagemaker_execution_role_arn | SageMaker execution role ARN |
| sagemaker_bucket_name | S3 bucket name for SageMaker artifacts |
| feature_store_bucket_name | S3 bucket name for Feature Store |
| model_package_groups | Map of model package group names to ARNs |
| sagemaker_config | Configuration object for other modules |

## Post-Deployment Steps

### 1. Configure SageMaker Studio
```bash
# Access SageMaker Studio via AWS Console or CLI
aws sagemaker describe-domain --domain-id <domain-id>
```

### 2. Set Up Feature Groups (via SDK)
```python
import boto3
from sagemaker.feature_store.feature_group import FeatureGroup

# Create feature group programmatically
feature_group = FeatureGroup(
    name="customer-features",
    sagemaker_session=sagemaker_session
)
```

### 3. Configure Model Monitoring
```python
from sagemaker.model_monitor import DefaultModelMonitor

# Set up data capture and monitoring
monitor = DefaultModelMonitor(
    role=execution_role,
    instance_count=1,
    instance_type='ml.m5.xlarge',
)
```

## Cost Optimization

### Development Environment
- Use smaller instance types (`ml.t3.medium`)
- Reduce log retention to 7 days
- Disable model monitoring for dev workloads

### Production Environment
- Use appropriate instance types based on workload
- Enable auto-scaling to handle variable traffic
- Set up proper data capture sampling rates

### Estimated Monthly Costs

| Component | Development | Production |
|-----------|-------------|------------|
| Studio Domain | $50 | $200 |
| Storage (S3) | $10 | $50 |
| Monitoring | $20 | $100 |
| **Total** | **$80** | **$350** |

## Security Best Practices

1. **Network Security**
   - Deploy in private subnets only
   - Use VPC endpoints for AWS services
   - Configure security groups appropriately

2. **Access Control**
   - Use least-privilege IAM roles
   - Enable resource-based policies
   - Implement proper user profile permissions

3. **Data Protection**
   - Enable KMS encryption for all resources
   - Use S3 bucket policies and public access blocks
   - Implement data classification and handling

4. **Monitoring and Compliance**
   - Enable CloudTrail logging
   - Set up Config rules for compliance
   - Implement resource tagging strategy

## Troubleshooting

### Common Issues

1. **Domain Creation Fails**
   ```bash
   # Check VPC and subnet configuration
   aws ec2 describe-subnets --subnet-ids subnet-12345678
   ```

2. **User Profile Access Issues**
   ```bash
   # Verify IAM role permissions
   aws iam get-role --role-name sagemaker-execution-role
   ```

3. **S3 Access Denied**
   ```bash
   # Check bucket policies and IAM permissions
   aws s3api get-bucket-policy --bucket my-sagemaker-bucket
   ```

## Examples

See the `examples/` directory for complete deployment examples:
- [Basic SageMaker Platform](../../examples/sagemaker-basic/)
- [Advanced MLOps Setup](../../examples/sagemaker-advanced/)

## Contributing

1. Update variables and validation rules as needed
2. Add comprehensive tests for new features
3. Update documentation and examples
4. Follow Terraform best practices for module development

## License

This module is released under the MIT License. See [LICENSE](../../LICENSE) for details.
