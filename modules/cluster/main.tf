variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = set(string)
}

variable "public_subnet_ids" {
  type = set(string)
}

variable "node_group_instance_type" {
  type = string
}

variable "node_group_scaling_config" {
  type = object({
    desired_size = number
    max_size     = number
    min_size     = number
  })
}

output "endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "ca_certificate" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "token" {
  value = data.aws_eks_cluster_auth.main.token
}
