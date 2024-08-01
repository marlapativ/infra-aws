locals {
  cluster_operations_values_files = [for file_path in var.eks_bootstrap_cluster_operations.values_file_paths : "${templatefile(file_path, {
    domain = var.domain,
    email  = var.email
  })}"]
}

resource "helm_release" "cluster_operations" {
  provider   = helm
  name       = var.eks_bootstrap_cluster_operations.name
  version    = var.eks_bootstrap_cluster_operations.version
  repository = var.eks_bootstrap_cluster_operations.repository
  chart      = var.eks_bootstrap_cluster_operations.chart
  namespace  = kubernetes_namespace.istio_system.metadata.0.name

  values = local.cluster_operations_values_files

  dynamic "set" {
    for_each = var.eks_bootstrap_cluster_operations.values
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    module.aws_load_balancer_controller,
    helm_release.istio_base,
    helm_release.istiod,
    helm_release.istio_gateway,
    helm_release.prometheus,
    helm_release.grafana
  ]
}
