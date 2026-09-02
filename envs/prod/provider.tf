provider "aws" {
    region = "us-east-1"
    allowed_account_ids = [ "059325865650" ]

    default_tags {
      tags = {
            Environment = "prod"
            ManagedBy   = "Terraform"
        }
    }
}

provider "helm" {
    # Enterprise Fix: Force Helm to cache locally in the project directory, 
    # so Windows Disk Cleanup can never corrupt the index files again.
    repository_config_path = "${path.module}/.helm/repositories.yaml"
    repository_cache       = "${path.module}/.helm/cache"

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