variable "push_initial_image" {
  type = bool
}

locals {
  name = "httpbin"
  port = 80
}

resource "aws_ecr_repository" "main" {
  name         = local.name
  force_delete = true
}

locals {
  ecr_registry_url = split("/", aws_ecr_repository.main.repository_url)[0]
}

output "ecr_registry_url" {
  value = local.ecr_registry_url
}

output "ecr_repository_url" {
  value = aws_ecr_repository.main.repository_url
}

data "aws_ecr_authorization_token" "main" {
  registry_id = aws_ecr_repository.main.registry_id
}

resource "null_resource" "upload_image_to_ecr" {
  count = var.push_initial_image ? 1 : 0

  provisioner "local-exec" {
    when = create

    environment = {
      // The environment variable hides the value from output.
      ECR_REGISTRY_PASSWORD = nonsensitive(data.aws_ecr_authorization_token.main.password)
    }

    command = <<EOF
echo $ECR_REGISTRY_PASSWORD | docker login --username AWS --password-stdin ${local.ecr_registry_url}

docker pull kennethreitz/httpbin:latest

docker tag kennethreitz/httpbin:latest ${aws_ecr_repository.main.repository_url}:latest

docker push ${aws_ecr_repository.main.repository_url}:latest
EOF
  }
}

resource "kubernetes_deployment_v1" "main" {
  depends_on = [
    null_resource.upload_image_to_ecr,
  ]

  wait_for_rollout = var.push_initial_image // Without an image, the deployment would never converge.

  metadata {
    name = local.name
    labels = {
      app = local.name
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = local.name
      }
    }

    template {
      metadata {
        labels = {
          app = local.name
        }
      }

      spec {
        container {
          image = "${aws_ecr_repository.main.repository_url}:latest" // Permission granted via EKS node role.
          name  = local.name

          port {
            container_port = local.port
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "main" {
  depends_on = [
    kubernetes_deployment_v1.main,
  ]

  metadata {
    name = local.name
  }

  spec {
    type = "NodePort"

    port {
      protocol    = "TCP"
      port        = local.port
      target_port = local.port
    }

    selector = {
      app = local.name
    }
  }
}

resource "kubernetes_ingress_v1" "main" {
  depends_on = [
    kubernetes_service_v1.main,
  ]

  metadata {
    name = local.name

    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }

  spec {
    default_backend {
      service {
        name = local.name
        port {
          number = local.port
        }
      }
    }
  }

  wait_for_load_balancer = true
}

output "ingress_host" {
  value = kubernetes_ingress_v1.main.status[0].load_balancer[0].ingress[0].hostname
}
