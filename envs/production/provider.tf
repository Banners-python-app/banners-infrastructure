provider "aws" {
    region = "us-east-1"

    default_tags {
      tags = {
            Environment = "prod"
            ManagedBy   = "Terraform"
        }
    }
}

provider "helm" {
    kubernetes  {
        host = module.eks.cluster_endpoint
        cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

        # automatically generates a temp login token using AWS local CLI role
        exec  {
          api_version = "client.authentication.k8s.io/v1beta1"
          args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
          command = "aws"
      }
    }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}