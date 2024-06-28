resource "kubernetes_storage_class" "ebs" {
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

resource "kubernetes_namespace" "namespaces" {
  provider = kubernetes
  count    = length(var.eks_namespaces)

  metadata {
    name = var.eks_namespaces[count.index]
  }
  depends_on = [module.eks]
}
