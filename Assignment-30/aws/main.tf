terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # These will be passed via -backend-config during init
    # bucket = "your-bucket-name"
    # key    = "terraform.tfstate"
    # region = "us-east-1"
    # dynamodb_table = "terraform-state-locks"
    # encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Create a simple S3 bucket as our demo resource
resource "aws_s3_bucket" "demo_bucket" {
  bucket = var.demo_bucket_name

  tags = {
    Name        = "Demo Bucket"
    Environment = "Demo"
  }
}

# Enable versioning on the demo bucket
resource "aws_s3_bucket_versioning" "demo_bucket" {
  bucket = aws_s3_bucket.demo_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add a simple object to the bucket to make changes more visible
resource "aws_s3_object" "demo_file" {
  bucket = aws_s3_bucket.demo_bucket.id
  key    = "demo.txt"
  source = "demo.txt"
  etag   = filemd5("demo.txt")
}

# Output the bucket details
output "demo_bucket_name" {
  value = aws_s3_bucket.demo_bucket.bucket
}

output "demo_bucket_arn" {
  value = aws_s3_bucket.demo_bucket.arn
}