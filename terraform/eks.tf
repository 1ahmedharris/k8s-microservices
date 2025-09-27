resource "aws_launch_template" "t4g_standard_burst" {
  name_prefix            = "site-t4g-standard-burst-"

  credit_specification {
    cpu_credits = "standard"
  }
}


module "eks_cluster" { 
  source                        = "terraform-aws-modules/eks/aws"
  version                       = "~> 21.1.0" # Terraform version 
  kubernetes_version            = "1.33" 
  name                          = "site-cluster"
  vpc_id                        = module.vpc.vpc_id       
  subnet_ids                    = module.vpc.private_subnets # provisions for control plane ENIs in private subnets 
  additional_security_group_ids = [module.cluster_sg.security_group_id] # Attach security_groups.tf cluster_sg 
  endpoint_private_access       = true
  enable_irsa                   = true

  # API server kubectl access/testing  
  # endpoint_public_access_cidrs = [
    # "MY.LOCAL.IP/32",        
    # "192.30.252.0/22",        # GitHub Actions IP ranges
    # "185.199.108.0/22"        # GitHub Actions IP ranges
 # ]


  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  

  eks_managed_node_groups = {
    "worker-nodes" = {
      instance_types                    = ["t4g.small"]
      capacity_type                     = "ON_DEMAND"
      ami_type                          = "AL2023_ARM_64_STANDARD"
      min_size                          = 1
      max_size                          = 2
      desired_size                      = 1
      disk_size                         = 20
      subnet_ids                        = module.vpc.private_subnets
      vpc_security_group_ids            = [module.node_group_sg.security_group_id]
      cluster_primary_security_group_id = module.eks_cluster.cluster_primary_security_group_id
      launch_template_id                = aws_launch_template.t4g_standard_burst.id
      create_iam_role                   = false
      node_role_arn                     = aws_iam_role.eks_node_role.arn      
    }
  }
}




