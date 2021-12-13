provider "aws" {
  region = "us-east-1"
  #alias  = "aws_cloudfront"
}

data "aws_iam_policy_document" "s3_content_bucket_policy" {
  statement {
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.content_bucket_name}/*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn,
      ]
    }
  }
}

resource "aws_s3_account_public_access_block" "s3_content_bucket_acl" {
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket" "s3_content_bucket" {
  bucket = var.content_bucket_name
   server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  acl = "private"
  versioning {
    enabled = false
  }
  policy = data.aws_iam_policy_document.s3_content_bucket_policy.json
  tags = var.tags
}

resource "aws_s3_bucket" "s3_log_bucket" {
  bucket = var.log_bucket_name
   server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  acl = "log-delivery-write"
  versioning {
    enabled = false
  }
  tags = var.tags
}
// cf distr with lambda@edge
resource "aws_cloudfront_distribution" "cf_distribution" {
  depends_on = [aws_s3_bucket.s3_content_bucket]

  origin {
    domain_name = "${var.content_bucket_name}.s3.amazonaws.com"
    origin_id   = "wwwprod"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.lambda_rewrite_uri.qualified_arn
      include_body = false
    }

    target_origin_id = "wwwprod"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  logging_config {
    bucket          = "${var.log_bucket_name}.s3.amazonaws.com"
    prefix          = "wwwprod"
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  tags = var.tags
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "CloudFront OAI for wwwprod"
}
# https://github.com/hashicorp/terraform-provider-aws/issues/1721
resource "time_sleep" "wait_30_seconds" {
depends_on = [aws_lambda_function.lambda_rewrite_uri]

destroy_duration = "1200s"
}

resource "null_resource" "next" {
depends_on = [time_sleep.wait_30_seconds]
}