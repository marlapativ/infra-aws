locals {
  kafka_values_files = [for file_path in var.eks_bootstrap_kafka.values_file_paths : "${file(file_path)}"]
}

resource "kubernetes_namespace" "kafka" {
  provider = kubernetes
  metadata {
    name = var.eks_bootstrap_kafka.namespace
  }
  depends_on = [module.eks]
}

resource "random_password" "kafka_password" {
  length  = var.password_defaults.length
  special = var.password_defaults.special
  upper   = var.password_defaults.upper
  numeric = var.password_defaults.numeric
  lower   = var.password_defaults.lower
}

resource "helm_release" "kafka" {
  provider   = helm
  name       = var.eks_bootstrap_kafka.name
  version    = var.eks_bootstrap_kafka.version
  repository = var.eks_bootstrap_kafka.repository
  chart      = var.eks_bootstrap_kafka.chart
  namespace  = kubernetes_namespace.kafka.metadata.0.name

  values = local.kafka_values_files

  dynamic "set" {
    for_each = var.eks_bootstrap_kafka.values
    content {
      name  = set.key
      value = set.value
    }
  }

  set {
    name  = "global.storageClass"
    value = kubernetes_storage_class.ebs.metadata.0.name
  }

  set_list {
    name  = "sasl.client.users"
    value = [var.eks_bootstrap_kafka_sensitive_values.username]
  }

  set_list {
    name  = "sasl.client.passwords"
    value = [random_password.kafka_password.result]
  }

  depends_on = [
    kubernetes_namespace.kafka,
    kubernetes_storage_class.ebs,
    random_password.kafka_password,
    module.eks.cluster_name
  ]
}
