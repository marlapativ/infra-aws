resource "kubernetes_namespace" "postgresql" {
  provider = kubernetes
  metadata {
    name = var.eks_bootstrap_postgresql.namespace
  }
  depends_on = [module.eks]
}

resource "random_password" "database_password" {
  length  = 24
  special = false
  upper   = true
  numeric = true
  lower   = true
}

resource "kubernetes_storage_class" "database_storage_class" {
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

resource "helm_release" "postgresql" {
  provider   = helm
  name       = var.eks_bootstrap_postgresql.name
  version    = var.eks_bootstrap_postgresql.version
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
    value = kubernetes_storage_class.database_storage_class.metadata.0.name
  }

  depends_on = [kubernetes_namespace.postgresql, random_password.database_password, kubernetes_storage_class.database_storage_class]
}
