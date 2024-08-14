
locals {
  llm_values_files      = [for file_path in var.eks_bootstrap_llm.values_file_paths : "${file(file_path)}"]
  ingestor_values_files = [for file_path in var.eks_bootstrap_ingestor.values_file_paths : "${file(file_path)}"]
}
resource "kubernetes_namespace" "llm" {
  provider = kubernetes
  metadata {
    name = var.eks_bootstrap_llm.namespace
    labels = {
      istio-injection = "enabled"
    }
  }
  depends_on = [
    module.eks.cluster_name,
    helm_release.postgresql,
    helm_release.kafka
  ]
}

resource "kubernetes_secret" "llm" {
  provider = kubernetes
  metadata {
    name      = "${kubernetes_namespace.llm.metadata.0.name}-dockerhub-secrets"
    namespace = kubernetes_namespace.llm.metadata.0.name
  }
  data = {
    ".dockerconfigjson" = base64decode(var.eks_bootstrap_secrets.dockerhubconfigjson)
  }
  type       = "kubernetes.io/dockerconfigjson"
  depends_on = [kubernetes_namespace.llm]
}

resource "kubernetes_default_service_account" "default" {
  metadata {
    namespace = kubernetes_namespace.llm.metadata.0.name
  }
  secret {
    name = kubernetes_secret.llm.metadata.0.name
  }
  depends_on = [kubernetes_namespace.llm, kubernetes_secret.llm]
}

resource "helm_release" "ollama" {
  provider   = helm
  name       = var.eks_bootstrap_llm.name
  version    = var.eks_bootstrap_llm.version
  repository = var.eks_bootstrap_llm.repository
  chart      = var.eks_bootstrap_llm.chart
  namespace  = kubernetes_namespace.llm.metadata.0.name

  values = local.llm_values_files

  dynamic "set" {
    for_each = var.eks_bootstrap_llm.values
    content {
      name  = set.key
      value = set.value
    }
  }

  set_sensitive {
    name  = "secrets.dockerhubconfigjson"
    value = var.eks_bootstrap_secrets.dockerhubconfigjson
  }

  depends_on = [kubernetes_namespace.llm, helm_release.kafka, helm_release.postgresql]
}


resource "helm_release" "ingestor" {
  provider   = helm
  name       = var.eks_bootstrap_ingestor.name
  version    = var.eks_bootstrap_ingestor.version
  repository = var.eks_bootstrap_ingestor.repository
  chart      = var.eks_bootstrap_ingestor.chart
  namespace  = kubernetes_namespace.llm.metadata.0.name

  values = local.ingestor_values_files

  dynamic "set" {
    for_each = var.eks_bootstrap_ingestor.values
    content {
      name  = set.key
      value = set.value
    }
  }

  set_sensitive {
    name  = "db.secrets.username"
    value = base64encode(var.eks_bootstrap_postgresql_sensitive_values.username)
  }

  set_sensitive {
    name  = "db.secrets.database"
    value = base64encode(var.eks_bootstrap_postgresql_sensitive_values.database)
  }

  set_sensitive {
    name  = "db.secrets.password"
    value = base64encode(random_password.database_password.result)
  }

  set_sensitive {
    name  = "db.secrets.postgresUsername"
    value = base64encode(var.eks_bootstrap_postgresql_sensitive_values.postgres_username)
  }

  set_sensitive {
    name  = "db.secrets.postgresPassword"
    value = base64encode(random_password.admin_database_password.result)
  }

  set_sensitive {
    name  = "kafka.secrets.username"
    value = base64encode(var.eks_bootstrap_kafka_sensitive_values.username)
  }

  set_sensitive {
    name  = "kafka.secrets.password"
    value = base64encode(random_password.kafka_password.result)
  }

  set_sensitive {
    name  = "secrets.dockerhubconfigjson"
    value = var.eks_bootstrap_secrets.dockerhubconfigjson
  }

  depends_on = [kubernetes_namespace.llm, helm_release.kafka, helm_release.postgresql, helm_release.ollama]
}

resource "kubernetes_limit_range" "llm" {
  count = length(var.eks_bootstrap_llm_limit_range) > 0 ? 1 : 0

  metadata {
    name      = "${kubernetes_namespace.llm.metadata.0.name}-limit-range"
    namespace = kubernetes_namespace.llm.metadata.0.name
  }

  dynamic "spec" {
    for_each = var.eks_bootstrap_llm_limit_range
    content {
      limit {
        type            = spec.value.type
        default         = try(spec.value.default, null)
        default_request = try(spec.value.default_request, null)
        min             = try(spec.value.min, null)
        max             = try(spec.value.max, null)
      }
    }
  }
}
