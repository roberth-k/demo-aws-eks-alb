// Follows the guide in: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html

variable "eks_cluster" {
  type = object({
    name              = string
    oidc_provider_arn = string
    oidc_provider_url = string
  })
}

data "http" "controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json"
}

resource "aws_iam_role" "main" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Principal = {
        Federated = var.eks_cluster.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.eks_cluster.oidc_provider_url}:aud" = "sts.amazonaws.com"
          "${var.eks_cluster.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }
  })

  inline_policy {
    name   = "aws-load-balancer-controller"
    policy = data.http.controller_policy.response_body
  }
}

resource "kubernetes_service_account_v1" "main" {
  metadata {
    labels = {
      "app.kubernetes.io/component" : "controller"
      "app.kubernetes.io/name" : "aws-load-balancer-controller"
    }
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.main.arn
    }
  }
}

resource "helm_release" "main" {
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  name       = "aws-load-balancer-controller"
  version    = "1.4.8"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.eks_cluster.name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account_v1.main.metadata[0].name
  }
}
