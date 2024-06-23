provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

resource "kubernetes_namespace" "processor" {
  provider = kubernetes
  metadata {
    name = "processor"
  }
}

resource "kubernetes_namespace" "kafka" {
  provider = kubernetes
  metadata {
    name = "kafka"
  }
}

resource "kubernetes_namespace" "consumer" {
  provider = kubernetes
  metadata {
    name = "consumer"
  }
}

resource "kubernetes_namespace" "database" {
  provider = kubernetes
  metadata {
    name = "database"
  }
}
