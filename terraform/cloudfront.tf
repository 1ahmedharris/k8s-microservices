locals {
  alb_origin_id = "eks-alb-origin"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "cloudfront_cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "EKS ALB/NGINX origin"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = var.cloudfront_aliases
  web_acl_id          = var.cloudfront_web_acl_arn 
  wait_for_deployment = true
  http_version        = "http2"

  origin {
    domain_name         = aws_lb.alb.dns_name  
    origin_id           = local.alb_origin_id 
    connection_attempts = 3
    connection_timeout  = 7

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"  # ALB terminates TLS
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    target_origin_id           = local.alb_origin_id
    allowed_methods            = ["GET", "HEAD"] 
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    viewer_protocol_policy     = "https-only"
  }

  restrictions {
    geo_restriction {
      locations        = var.cloudfront_restriction_locations
      restriction_type = var.cloudfront_restriction_type
    }
  }

  viewer_certificate {
    acm_certificate_arn        = var.acm_certificate_arn
    minimum_protocol_version   = "TLSv1.2_2021"
    ssl_support_method         = "sni-only"
  }
}
