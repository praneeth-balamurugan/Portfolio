provider "aws" {
  region = "ap-south-1"
}

data "aws_s3_bucket" "existing_bucket" {
  bucket = "terraform-pre-098765"
}

resource "aws_s3_bucket" "mybucket" {
  count  = data.aws_s3_bucket.existing_bucket.bucket != null ? 0 : 1
  bucket = "terraform-final-09876"
}

resource "aws_s3_bucket_website_configuration" "mybucket_website" {
  bucket = data.aws_s3_bucket.existing_bucket.bucket != null ? data.aws_s3_bucket.existing_bucket.bucket : aws_s3_bucket.mybucket[0].bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = data.aws_s3_bucket.existing_bucket.bucket != null ? data.aws_s3_bucket.existing_bucket.bucket : aws_s3_bucket.mybucket[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = data.aws_s3_bucket.existing_bucket.bucket != null ? data.aws_s3_bucket.existing_bucket.bucket : aws_s3_bucket.mybucket[0].id

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

  bucket = data.aws_s3_bucket.existing_bucket.bucket != null ? data.aws_s3_bucket.existing_bucket.bucket : aws_s3_bucket.mybucket[0].id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "mybucket_policy" {
  bucket = data.aws_s3_bucket.existing_bucket.bucket != null ? data.aws_s3_bucket.existing_bucket.bucket : aws_s3_bucket.mybucket[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${data.aws_s3_bucket.existing_bucket.bucket != null ? data.aws_s3_bucket.existing_bucket.arn : aws_s3_bucket.mybucket[0].arn}/*"
      }
    ]
  })
}
