variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = set(string)
}

resource "aws_eks_cluster" "main" {
  depends_on = [
    aws_cloudwatch_log_group.main,
  ]

  name     = var.cluster_name
  role_arn = aws_iam_role.main.arn

  version = "1.25" // https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html

  // https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  vpc_config {
    endpoint_public_access = true // WARNING: Bastion would be safer -- this is for demo only.
    subnet_ids             = var.private_subnet_ids
    security_group_ids     = [aws_security_group.main.id]
  }
}

output "name" {
  value = aws_eks_cluster.main.name
}

output "endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "ca_certificate" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

output "token" {
  value = data.aws_eks_cluster_auth.main.token
}

resource "aws_cloudwatch_log_group" "main" {
  name = "/aws/eks/${var.cluster_name}/cluster"
}

resource "aws_iam_role" "main" {
  name = "eks-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }
  })

  managed_policy_arns = [
    // Required for any cluster.
    // https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
  ]
}

resource "aws_security_group" "main" {
  name        = "eks-${var.cluster_name}"
  description = "eks-${var.cluster_name}"
  vpc_id      = var.vpc_id

  tags = {
    Name = "eks-${var.cluster_name}"
  }
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.cluster.url
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.main.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.main.url
}

resource "aws_eks_node_group" "main" {
  ami_type        = "AL2_ARM_64"
  cluster_name    = aws_eks_cluster.main.name
  instance_types  = ["t4g.small"]
  node_group_name = "main"
  node_role_arn   = aws_iam_role.node.arn

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  subnet_ids = var.private_subnet_ids
}

resource "aws_iam_role" "node" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }
  })

  // Required policies from:
  // https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]
}
