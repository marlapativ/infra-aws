resource "kubernetes_namespace" "postgresql" {
  provider = kubernetes
  metadata {
    name = var.eks_bootstrap_postgresql.namespace
  }
  depends_on = [module.eks]
}

resource "random_password" "database_password" {
  length           = 24
  special          = false
  upper            = true
  numeric          = true
  lower            = true
}

resource "helm_release" "postgresql" {
  provider   = helm
  name       = var.eks_bootstrap_postgresql.name
  repository = var.eks_bootstrap_postgresql.repository
  chart      = var.eks_bootstrap_postgresql.chart
  namespace  = kubernetes_namespace.postgresql.metadata.0.name

  dynamic "set" {
    for_each = var.eks_bootstrap_postgresql.values
    content {
      name  = set.key
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = var.eks_bootstrap_postgresql_sensitive_values
    content {
      name  = set.key
      value = set.value
    }
  }

  set {
    name  = "postgres.db.password"
    value = random_password.database_password.result
  }

  depends_on = [kubernetes_namespace.postgresql, random_password.database_password]
}
