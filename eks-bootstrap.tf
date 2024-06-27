provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

resource "kubernetes_storage_class" "ebs" {
  provider = kubernetes
  metadata {
    name = var.eks_storage_class.storage_class_name
  }
  storage_provisioner = var.eks_storage_class.storage_provisioner
  reclaim_policy      = var.eks_storage_class.reclaim_policy
  volume_binding_mode = var.eks_storage_class.volume_binding_mode
  parameters = merge(var.eks_storage_class.parameters, {
    "kmsKeyId" : module.kms_ebs.key_arn
    "encrypted" : "true"
  })
}

resource "kubernetes_namespace" "processor" {
  provider = kubernetes
  metadata {
    name = "processor"
  }
  depends_on = [module.eks]
}

resource "kubernetes_namespace" "consumer" {
  provider = kubernetes
  metadata {
    name = "consumer"
  }
  depends_on = [module.eks]
}
