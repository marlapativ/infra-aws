resource "kubernetes_namespace" "istio_system" {
  provider = kubernetes
  metadata {
    name = var.eks_bootstrap_istiod.namespace
  }
  depends_on = [kubernetes_namespace.operations]
}

locals {
  istio_base_values_files    = [for file_path in var.eks_bootstrap_istio_base.values_file_paths : "${file(file_path)}"]
  istiod_values_files        = [for file_path in var.eks_bootstrap_istiod.values_file_paths : "${file(file_path)}"]
  istio_gateway_values_files = [for file_path in var.eks_bootstrap_istio_gateway.values_file_paths : "${file(file_path)}"]
}

resource "helm_release" "istio_base" {
  provider   = helm
  name       = var.eks_bootstrap_istio_base.name
  version    = var.eks_bootstrap_istio_base.version
  repository = var.eks_bootstrap_istio_base.repository
  chart      = var.eks_bootstrap_istio_base.chart
  namespace  = kubernetes_namespace.istio_system.metadata.0.name

  values = local.istiod_values_files

  dynamic "set" {
    for_each = var.eks_bootstrap_istio_base.values
    content {
      name  = set.key
      value = set.value
    }
  }

  set {
    name  = "defaultRevision"
    value = "default"
  }

  depends_on = [kubernetes_namespace.istio_system]
}

resource "helm_release" "istiod" {
  provider   = helm
  name       = var.eks_bootstrap_istiod.name
  version    = var.eks_bootstrap_istiod.version
  repository = var.eks_bootstrap_istiod.repository
  chart      = var.eks_bootstrap_istiod.chart
  namespace  = kubernetes_namespace.istio_system.metadata.0.name

  values = local.istiod_values_files

  dynamic "set" {
    for_each = var.eks_bootstrap_istiod.values
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [kubernetes_namespace.istio_system, helm_release.istio_base]
}

module "aws_load_balancer_controller" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true
}

resource "helm_release" "istio_gateway" {
  provider   = helm
  name       = var.eks_bootstrap_istio_gateway.name
  version    = var.eks_bootstrap_istio_gateway.version
  repository = var.eks_bootstrap_istio_gateway.repository
  chart      = var.eks_bootstrap_istio_gateway.chart
  namespace  = kubernetes_namespace.istio_system.metadata.0.name

  values = local.istio_gateway_values_files

  dynamic "set" {
    for_each = var.eks_bootstrap_istio_gateway.values
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [module.aws_load_balancer_controller, kubernetes_namespace.istio_system, helm_release.istio_base, helm_release.istiod]
}
