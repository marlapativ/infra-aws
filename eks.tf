locals {
  node_groups = {
    for prop in var.eks_cluster.node_groups : prop.name => prop
  }
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.14.0"

  authentication_mode = var.eks_cluster.authentication_mode

  // EKS Cluster configuration
  cluster_name                    = var.eks_cluster.name
  cluster_version                 = var.eks_cluster.version
  cluster_endpoint_public_access  = var.eks_cluster.endpoint_public_access
  cluster_endpoint_private_access = var.eks_cluster.endpoint_private_access

  // KMS Symmetric Secretes encryption Keys
  create_kms_key                = true
  kms_key_description           = "Amazon EKS cluster secrets encryption key"
  kms_key_enable_default_policy = true
  cluster_encryption_config = {
    "resources" : ["secrets"]
  }

  // EKS Cluster service role.
  create_iam_role = true
  iam_role_name   = "${var.eks_cluster.name}-service-role"

  // EKS Cluster Addons
  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
      most_recent              = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  // EKS Cluster logging configuration
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  enable_cluster_creator_admin_permissions = true

  vpc_id     = aws_vpc.cluster.id
  subnet_ids = aws_subnet.private[*].id

  dataplane_wait_duration = "900s"

  // EKS Managed Node Groups Defaults
  eks_managed_node_group_defaults = {
    ami_type = var.eks_cluster.ami_type
  }

  // EKS Managed Node Groups
  eks_managed_node_groups = local.node_groups
}
