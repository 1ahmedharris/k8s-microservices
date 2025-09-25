resource "aws_launch_template" "t4g_standard_burst" {
  name_prefix            = "site-t4g-standard-burst-"

  credit_specification {
    cpu_credits = "standard"
  }
}


module "eks_cluster" { 
  source                  = "terraform-aws-modules/eks/aws"
  version                 = "~> 21.1.0" # Terraform version 
  kubernetes_version      = "1.33" 
  name                    = "site-cluster"
  vpc_id                  = module.vpc.vpc_id       
  subnet_ids              = module.vpc.private_subnets # provisions for control plane cross-account ENIs in private subnets 
  endpoint_private_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }
  

  eks_managed_node_groups = {
    "worker-nodes" = {
      instance_types       = ["t4g.small"]
      capacity_type        = "ON_DEMAND"
      ami_type             = "AL2023_ARM_64_STANDARD"
      min_size             = 1
      max_size             = 2
      desired_size         = 1
      subnet_ids           = module.vpc.private_subnets
      security_groups      = [module.node_group_sg.security_group_id]
      launch_template_id   = aws_launch_template.t4g_standard_burst.id
      # node_role_arn      = aws_iam_role.resume_eks_node_role.arn      
    }
  }
}

