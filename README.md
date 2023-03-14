Minimal demo: AWS EKS with ALB
==============================

- Uses the default backend configuration (local file named `terraform.tfstate` -- **this has been .gitignore-d!**).
- AWS authentication requires additional configuration, such as selecting a CLI profile. For more, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration.
- This repository can build a minimal EKS cluster with an ALB, and omits as much detail as possible. **It does not demonstrate best practice or last privilege -- be mindful of your observability and IAM policies!**
- To deploy it, run `terraform init` followed by `terraform apply`.
- Requires Terraform 1.3 or above.
- Estimated cost to run (in `eu-west-1`): 0.2376 $/hr = 5.7 $/day = 171 $/month
    - VPC NAT Gateways (2x): 2*0.048 $/hr = 0.096 $/hr
    - EKS Cluster: $0.10 /hr
    - EKS Node Group (2x `t3.small`): 2*0.0208 $/hr
