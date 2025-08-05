resource "aws_iam_role" "github_actions_eks_role" {
  name = "github-actions-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${var.aws_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org_name}/${var.github_repo_name}:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_eks_policy" {
  name        = "github-actions-eks-policy"
  description = "Policy allowing GitHub Actions to provision infrastructure for Terraform and EKS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:ListPolicies"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:DeletePolicyVersion",
          "iam:CreatePolicyVersion"
        ],
        Resource = "*"
      },

      # CloudFront permissions
      {
        Effect = "Allow",
        Action = [
          "cloudfront:ListTagsForResource",
          "cloudfront:UpdateDistribution",
          "cloudfront:GetDistribution",
          "cloudfront:CreateInvalidation",
          "cloudfront:ListCachePolicies",
          "cloudfront:GetDistributionConfig",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:GetCachePolicy"
        ],
        Resource = "*"
      },

      # ACM
      {
        Effect = "Allow",
        Action = [
          "acm:DescribeCertificate",
          "acm:ListTagsForResource" 
        ],
        Resource = "${var.acm_certificate_arn}"
      },

      # WAFv2
      {
        Effect = "Allow",
        Action = [
          "wafv2:GetWebACL",
          "wafv2:ListWebACLs",
          "wafv2:ListTagsForResource" 
        ],
        Resource = "${var.cloudfront_web_acl_arn}"
      },

      {
        Effect = "Allow",
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketTagging",
          "s3:ListBucket",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketWebsite"
        ],
        Resource = "*"
      },

      # S3 bucket permissions
      {
        Effect = "Allow",
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketLocation",
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy",
          "s3:PutBucketVersioning",
          "s3:GetBucketVersioning",
          "s3:PutEncryptionConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketAcl",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketLogging",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:GetBucketObjectLockConfiguration"
        ],
        Resource = "arn:aws:s3:::${var.s3_bucket}"
      },

      # S3 object permissions
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource = "arn:aws:s3:::${var.s3_bucket}/*"
      },

      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::resume-remote-backend",
          "arn:aws:s3:::resume-remote-backend/*"
        ]
      },

      # Lambda permissions
      {
        Effect = "Allow",
        Action = [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:InvokeFunction",
          "lambda:CreateFunctionUrlConfig",
          "lambda:UpdateFunctionUrlConfig",
          "lambda:GetFunctionUrlConfig",
          "lambda:ListTags",
          "lambda:ListFunctions",
          "lambda:ListVersionsByFunction",
          "lambda:ListAliases",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetPolicy"
        ],
        Resource = "*"
      },


      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = "arn:aws:iam::${var.aws_id}:role/lamba-dynamodb-role",
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      },

      # Lambda dynamodb permissions

            {
        Effect = "Allow",
        Action = [
          "dynamodb:DescribeTimeToLive"
        ],
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_id}:table/*"
        ]
      },

      {
        Effect = "Allow",
        Action = [
          "dynamodb:ListTagsOfResource",
        ],
        Resource = "*"
      },

      {
        Effect = "Allow",
        Action = [
          "dynamodb:UpdateTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DescribeTable",
          "dynamodb:DeleteItem",
          "dynamodb:ListTables",
          "dynamodb:DescribeContinuousBackups"
        ],
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_id}:table/visitor-count-table",
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_id}:table/*"
        ]
      },

      # Route 53 permissions
      {
        Effect = "Allow",
        Action = [
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
          "route53:GetHostedZone",
          "route53:ListTagsForResource",
          "route53:ListResourceRecordSets"
        ],
        Resource = "*"
      },

      {
        Effect = "Allow",
        Action = [
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource"
        ],
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_id}:log-group:*"
      },

      # CloudWatch Logs for Lambda
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "github_actions_eks_policy_attachment" {
  role       = aws_iam_role.github_actions_eks_role.name
  policy_arn = aws_iam_policy.github_actions_eks_policy.arn
}
