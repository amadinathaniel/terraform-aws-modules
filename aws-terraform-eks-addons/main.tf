# ==============================================================================
# 1. OIDC Provider (for IRSA)
# ==============================================================================
data "tls_certificate" "eks" {
  count = var.enable_oidc_provider ? 1 : 0
  url   = var.oidc_provider_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  count           = var.enable_oidc_provider ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks[0].certificates[0].sha1_fingerprint]
  url             = var.oidc_provider_url

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-oidc-provider"
    Component = "eks-addons"
  })
}

# ==============================================================================
# 2. Pod Identity Agent
# ==============================================================================
resource "aws_eks_addon" "pod_identity" {
  count         = var.enable_pod_identity ? 1 : 0
  cluster_name  = var.cluster_name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.10-eksbuild.1"

  tags = merge(var.common_tags, {
    Component = "eks-addons"
  })
}

# ==============================================================================
# 3. EBS CSI Driver
# ==============================================================================
data "aws_iam_policy_document" "ebs_csi_assume" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver" {
  count              = var.enable_ebs_csi_driver ? 1 : 0
  name               = "${var.cluster_name}-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume[0].json

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-ebs-csi-driver"
    Component = "eks-addons"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count      = var.enable_ebs_csi_driver ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}

resource "aws_iam_policy" "ebs_csi_driver_encryption" {
  count = var.enable_ebs_csi_driver ? 1 : 0
  name  = "${var.cluster_name}-ebs-csi-driver-encryption"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Component = "eks-addons"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_encryption" {
  count      = var.enable_ebs_csi_driver ? 1 : 0
  policy_arn = aws_iam_policy.ebs_csi_driver_encryption[0].arn
  role       = aws_iam_role.ebs_csi_driver[0].name
}

resource "aws_eks_pod_identity_association" "ebs_csi_driver" {
  count           = var.enable_ebs_csi_driver && var.enable_pod_identity ? 1 : 0
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_driver[0].arn
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count                    = var.enable_ebs_csi_driver ? 1 : 0
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.55.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver[0].arn

  tags = merge(var.common_tags, {
    Component = "eks-addons"
  })

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver,
    aws_iam_role_policy_attachment.ebs_csi_driver_encryption,
  ]
}

# ==============================================================================
# 4. Metrics Server (EKS Community Addon)
# ==============================================================================
resource "aws_eks_addon" "metrics_server" {
  count         = var.enable_metrics_server ? 1 : 0
  cluster_name  = var.cluster_name
  addon_name    = "metrics-server"
  addon_version = "v0.8.0-eksbuild.1"

  tags = merge(var.common_tags, {
    Component = "eks-addons"
  })
}
