locals {
  postgres_values_files = [for file_path in var.eks_bootstrap_postgresql.values_file_paths : "${file(file_path)}"]
}

resource "kubernetes_namespace" "postgresql" {
  provider = kubernetes
  metadata {
    name = var.eks_bootstrap_postgresql.namespace
  }
  depends_on = [module.eks]
}

resource "random_password" "database_password" {
  length  = var.password_defaults.length
  special = var.password_defaults.special
  upper   = var.password_defaults.upper
  numeric = var.password_defaults.numeric
  lower   = var.password_defaults.lower
}

resource "helm_release" "postgresql" {
  provider   = helm
  name       = var.eks_bootstrap_postgresql.name
  version    = var.eks_bootstrap_postgresql.version
  repository = var.eks_bootstrap_postgresql.repository
  chart      = var.eks_bootstrap_postgresql.chart
  namespace  = kubernetes_namespace.postgresql.metadata.0.name

  values = local.postgres_values_files

  dynamic "set" {
    for_each = var.eks_bootstrap_postgresql.values
    content {
      name  = set.key
      value = set.value
    }
  }

  set_sensitive {
    name  = "global.postgresql.auth.username"
    value = var.eks_bootstrap_postgresql_sensitive_values.username
  }

  set_sensitive {
    name  = "global.postgresql.auth.database"
    value = var.eks_bootstrap_postgresql_sensitive_values.database
  }

  set_sensitive {
    name  = "global.postgresql.auth.password"
    value = random_password.database_password.result
  }

  set {
    name  = "global.storageClass"
    value = kubernetes_storage_class.ebs.metadata.0.name
  }

  depends_on = [
    kubernetes_namespace.postgresql,
    random_password.database_password,
    kubernetes_storage_class.ebs,
    module.eks.cluster_name
  ]
}
