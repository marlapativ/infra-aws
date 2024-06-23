provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = module.eks.cluster_certificate_authority_data
    host                   = module.eks.cluster_endpoint
  }
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
