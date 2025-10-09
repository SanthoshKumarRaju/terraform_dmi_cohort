variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "demo_bucket_name" {
  description = "Name for the demo S3 bucket (must be globally unique)"
  type        = string
}