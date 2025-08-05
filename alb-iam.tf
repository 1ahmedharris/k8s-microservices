# This policy must be downloaded from the official AWS GitHub repo:
# Place it in the same module directory as alb-iam.tf.
# curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

# Retrieve the EKS cluster and its authentication details
data "aws_eks_cluster" "site_cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "eks_auth" {
  name = var.cluster_name
}

# Reference the OIDC provider
data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = data.aws_eks_cluster.site_cluster.identity[0].oidc[0].issuer
}

# Create the IAM policy for the AWS Load Balancer Controller
resource "aws_iam_policy" "alb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/iam-policy.json")  # Download this policy from AWS docs
}

# Create the IAM Role assumed by the ALB Controller's Service Account
resource "aws_iam_role" "alb_controller_role" {
  name = "alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.site_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
}

# Attach the policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_alb_controller" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

