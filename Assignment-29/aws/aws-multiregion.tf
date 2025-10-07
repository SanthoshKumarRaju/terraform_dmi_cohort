terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# --- AWS Providers (two regions) ---
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "euc1"
  region = "eu-central-1"
}

# --- Random Suffix for Uniqueness ---
resource "random_id" "use1_suffix" {
  byte_length = 3
}

resource "random_id" "euc1_suffix" {
  byte_length = 3
}

# --- S3 Bucket in us-east-1 ---
resource "aws_s3_bucket" "use1_assets" {
  provider = aws.use1
  bucket   = "company-dev-assets-use1-${random_id.use1_suffix.hex}"

  tags = {
    project = "multicloud-foundation"
    owner   = "your-name"
    env     = "dev"
  }
}

resource "aws_s3_bucket_versioning" "use1_versioning" {
  provider = aws.use1
  bucket   = aws_s3_bucket.use1_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- S3 Bucket in eu-central-1 ---
resource "aws_s3_bucket" "euc1_assets" {
  provider = aws.euc1
  bucket   = "company-dev-assets-euc1-${random_id.euc1_suffix.hex}"

  tags = {
    project = "multicloud-foundation"
    owner   = "your-name"
    env     = "dev"
  }
}

resource "aws_s3_bucket_versioning" "euc1_versioning" {
  provider = aws.euc1
  bucket   = aws_s3_bucket.euc1_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}
