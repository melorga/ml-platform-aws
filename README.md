# ml-platform-aws

> **Status: experimental, single-module reference implementation.**
> This repository ships one Terraform module. It is a portfolio / reference
> example, not a production-ready platform. Treat it as a starting point.

A Terraform module that provisions a small SageMaker footprint on AWS:

- **SageMaker Studio Domain** (IAM auth) with configurable user profiles
- **Model Registry** (Model Package Groups)
- **S3 buckets** for SageMaker artifacts, Feature Store offline storage, and
  Model Monitor output (KMS-encrypted, versioned, public access blocked)
- **KMS key** dedicated to the platform, scoped to the SageMaker service
- **CloudWatch Log Groups** for training / endpoint / processing jobs
- **EventBridge -> Lambda -> SNS** pipeline that forwards SageMaker Model
  Monitor execution status changes as alerts
- **IAM roles** for SageMaker execution, Feature Store, Step Functions, and
  SageMaker Pipelines, written as least-privilege inline policies (no
  `AmazonSageMakerFullAccess` attachment)

## Repository layout

```
ml-platform-aws/
  modules/
    sagemaker-platform/   # the module
      main.tf
      iam.tf
      variables.tf
      outputs.tf
      versions.tf
  examples/
    basic/                # minimal usage example
  .github/
    workflows/terraform.yml
    dependabot.yml
```

There are no other modules, environments, pipelines, EKS clusters, or test
suites in this repo. The previous README claimed those existed; it was
aspirational and has been removed.

## Requirements

| Tool          | Version  |
|---------------|----------|
| Terraform     | >= 1.9.0 |
| AWS provider  | ~> 6.0   |

You will need an AWS account, a VPC with at least two private subnets, and
credentials with permission to create SageMaker, IAM, S3, KMS, CloudWatch,
EventBridge, Lambda, and SNS resources.

## Usage

```hcl
module "sagemaker_platform" {
  source = "github.com/melorga/ml-platform-aws//modules/sagemaker-platform"

  project_name = "ml-demo"
  domain_name  = "ml-demo-studio"
  environment  = "dev"

  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-aaa", "subnet-bbb"]

  user_profiles        = ["data-scientist", "ml-engineer"]
  model_package_groups = ["classification-models"]

  tags = {
    Project = "ml-demo"
    Owner   = "platform"
  }
}
```

A runnable example is in [`examples/basic/`](./examples/basic/).

## Inputs

See [`modules/sagemaker-platform/variables.tf`](./modules/sagemaker-platform/variables.tf)
for the full input schema and validation rules. Notable defaults:

- `default_instance_type = "ml.t3.medium"` (validated against a list that
  includes m5/m6i, c5/c6i, Graviton m7g/c7g, and g5 families)
- `log_retention_days = 30`
- `enable_model_monitoring = true`

## Outputs

See [`modules/sagemaker-platform/outputs.tf`](./modules/sagemaker-platform/outputs.tf).
Includes Studio domain ID/ARN/URL, bucket names/ARNs, KMS key ID/ARN, IAM
role ARNs, log group names, SNS topic ARN, and a flattened `sagemaker_config`
object for chaining into downstream modules.

## CI

A GitHub Actions workflow runs on every PR and push to `main`:

- `terraform fmt -check -recursive`
- `terraform validate` against `examples/basic`
- [`tflint`](https://github.com/terraform-linters/tflint) recursive
- [`trivy config`](https://github.com/aquasecurity/trivy-action) with SARIF
  upload to GitHub Security

## Caveats

- The module assumes the VPC and private subnets already exist.
- The Lambda alert handler is intentionally a placeholder; it publishes a
  formatted message to SNS but does no triage.
- `aws_sagemaker_domain` can take 5-10 minutes to create or destroy.
- This is a reference implementation. Review the IAM policies and KMS
  resource policy against your own threat model before using in production.

## License

MIT - see [LICENSE](./LICENSE).
