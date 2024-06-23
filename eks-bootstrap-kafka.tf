resource "kubernetes_namespace" "kafka" {
  provider = kubernetes
  metadata {
    name = var.eks_bootstrap_kafka.namespace
  }
  depends_on = [module.eks]
}

resource "helm_release" "kafka" {
  provider   = helm
  name       = var.eks_bootstrap_kafka.name
  version    = var.eks_bootstrap_kafka.version
  repository = var.eks_bootstrap_kafka.repository
  chart      = var.eks_bootstrap_kafka.chart
  namespace  = kubernetes_namespace.kafka.metadata.0.name

  dynamic "set" {
    for_each = var.eks_bootstrap_kafka.values
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [kubernetes_namespace.kafka]
}
