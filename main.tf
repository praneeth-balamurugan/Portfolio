provider "aws" {
  region = "ap-south-1"
}

data "aws_s3_bucket" "existing_bucket" {
  bucket = "terraform-final-098765"
}

resource "aws_s3_bucket" "mybucket" {
  bucket = "terraform-final-09876"
  count  = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? 1 : 0
}

resource "aws_s3_bucket_website_configuration" "mybucket_website" {
  bucket = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? aws_s3_bucket.mybucket[0].bucket : data.aws_s3_bucket.existing_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? aws_s3_bucket.mybucket[0].id : data.aws_s3_bucket.existing_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? aws_s3_bucket.mybucket[0].id : data.aws_s3_bucket.existing_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? aws_s3_bucket.mybucket[0].id : data.aws_s3_bucket.existing_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "mybucket_policy" {
  bucket = length(data.aws_s3_bucket.existing_bucket.id) == 0 ? aws_s3_bucket.mybucket[0].id : data.aws_s3_bucket.existing_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${length(data.aws_s3_bucket.existing_bucket.id) == 0 ? aws_s3_bucket.mybucket[0].arn : data.aws_s3_bucket.existing_bucket.arn}/*"
      }
    ]
  })
}
