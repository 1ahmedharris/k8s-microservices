variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr_blocks" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}
