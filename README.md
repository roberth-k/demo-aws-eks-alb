Minimal demo: AWS EKS with ALB
==============================

- Uses the default backend configuration (local file named `terraform.tfstate` -- **this has been `.gitignore`-d!**).
- AWS authentication requires additional configuration, such as selecting a CLI profile. For more, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration.
- This repository can build a minimal EKS cluster with an ALB, and omits as much detail as possible. **It does not demonstrate security, best practice, nor least privilege -- be mindful of your observability, public access, and IAM policies!**
- Requires:
    - Terraform 1.3 or above.
    - Docker CLI.
- Estimated cost to run (in `eu-west-1`): 0.2628 $/hr = 6.3 $/day = 189 $/month
  - VPC NAT Gateways (2x): 2*0.048 $/hr = 0.096 $/hr
  - EKS Cluster: $0.10 /hr
  - EKS Node Group (2x `t3.small`): 2*0.0208 $/hr
  - Application Load Balancer: 0.0252 $/hr
- To deploy it, run `terraform init` followed by `terraform apply`. It takes ~15 minutes to complete.
    - To seed the ECR repository of the `httpbin` service, the module will use a provisioner to execute local `docker` commands. To switch this behaviour off, set the `push_initial_image` variable of the module to `false`.
- Upon completion, the cluster will run [httpbin](https://github.com/postmanlabs/httpbin) fronted by an ALB. The ALB hostname is given by the `httpbin_ingress_host` output value.
- You might see `Warning: "default_secret_name" is no longer applicable for Kubernetes v1.24.0 and above`. Although it doesn't apply to this demo, this warning can't be suppressed (see [this issue](https://github.com/hashicorp/terraform-provider-kubernetes/issues/1990)).
- To tear it down, run `terraform destroy`.
