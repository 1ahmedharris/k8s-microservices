vpc_cidr_block     = "10.0.0.0/20"
cluster_name       = "site-cluster"

public_subnet_cidr_blocks = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

private_subnet_cidr_blocks = [
  "10.0.4.0/24",
  "10.0.5.0/24",
  "10.0.6.0/24"
]

cluster_name = "eks-cluster"
