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
