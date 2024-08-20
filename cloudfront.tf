# S3 Bucket
resource "aws_s3_bucket" "static_site_bucket" {
    bucket_prefix = var.site_name
    tags = var.tags
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.static_site_bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [
        aws_cloudfront_distribution.s3_distribution.arn
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
    bucket = aws_s3_bucket.static_site_bucket.id
    policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.site_name}_oac"
  description                       = "Origin Access Control for ${var.site_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "index_forward" {
  name    = "test"
  runtime = "cloudfront-js-2.0"
  comment = "forward-index-html"
  publish = true
  code    = file("${path.module}/function/function.js")
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static_site_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = var.site_name
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.site_description
  default_root_object = "index.html"

  aliases = [var.site_url]

  custom_error_response {
      error_code            = 403
      response_code         = 404
      response_page_path    = "/404.html"
      error_caching_min_ttl = 3600
    }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.site_name

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.index_forward.arn
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "ZA", "PH"]
    }
  }

  tags = var.tags

  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn = module.cloudfront_cert.certificate_arn
    ssl_support_method = "sni-only"
  }
}

# Route53 Record Set
data "aws_route53_zone" "r53_zone" {
  name         = var.site_hosted_zone
  private_zone = false
}
resource "aws_route53_record" "cloudfront_record" {
  zone_id = data.aws_route53_zone.r53_zone.zone_id
  name    = var.site_url
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

module "cloudfront_cert" {
  source = "./us-east-1-cert"
  site_url = var.site_url
  site_hosted_zone = var.site_hosted_zone
  tags = var.tags
}