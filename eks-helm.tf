provider "helm" {
  kubernetes {
    cluster_ca_certificate = module.eks.cluster_certificate_authority_data
    host                   = module.eks.cluster_endpoint
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
}
