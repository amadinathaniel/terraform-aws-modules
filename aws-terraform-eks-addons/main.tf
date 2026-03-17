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

  lifecycle {
    precondition {
      condition     = var.enable_pod_identity
      error_message = "enable_pod_identity must be true to create pod identity associations for EBS CSI driver."
    }
  }
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
# 4. Metrics Server
# ==============================================================================
resource "helm_release" "metrics_server" {
  count      = var.enable_metrics_server ? 1 : 0
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.2"
}

# ==============================================================================
# 5. Cluster Autoscaler
# ==============================================================================
data "aws_iam_policy_document" "cluster_autoscaler_assume" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  count              = var.enable_cluster_autoscaler ? 1 : 0
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume[0].json

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-cluster-autoscaler"
    Component = "eks-addons"
  })
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "${var.cluster_name}-cluster-autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Component = "eks-addons"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = aws_iam_role.cluster_autoscaler[0].name
}

resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  count           = var.enable_cluster_autoscaler && var.enable_pod_identity ? 1 : 0
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler[0].arn
}

resource "helm_release" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  name       = "autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.54.0"

  set = [
    {
      name  = "rbac.serviceAccount.name"
      value = "cluster-autoscaler"
    },
    {
      name  = "autoDiscovery.clusterName"
      value = var.cluster_name
    },
    # MUST be updated to match your region 
    {
      name  = "awsRegion"
      value = var.aws_region
    }
  ]

  lifecycle {
    precondition {
      condition     = !var.enable_cluster_autoscaler || var.enable_metrics_server
      error_message = "enable_metrics_server must be true when enable_cluster_autoscaler is true."
    }
  }

  depends_on = [helm_release.metrics_server]
}

# ==============================================================================
# 6. AWS Load Balancer Controller
# ==============================================================================
data "aws_iam_policy_document" "aws_lbc_assume" {
  count = var.enable_aws_lbc ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "aws_lbc" {
  count              = var.enable_aws_lbc ? 1 : 0
  name               = "${var.cluster_name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc_assume[0].json

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-aws-lbc"
    Component = "eks-addons"
  })
}

resource "aws_iam_policy" "aws_lbc" {
  count = var.enable_aws_lbc ? 1 : 0
  name  = "${var.cluster_name}-aws-lbc"

  policy = file("${path.module}/iam/AWSLoadBalancerController.json")

  tags = merge(var.common_tags, {
    Component = "eks-addons"
  })
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  count      = var.enable_aws_lbc ? 1 : 0
  policy_arn = aws_iam_policy.aws_lbc[0].arn
  role       = aws_iam_role.aws_lbc[0].name
}

resource "aws_eks_pod_identity_association" "aws_lbc" {
  count           = var.enable_aws_lbc && var.enable_pod_identity ? 1 : 0
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_lbc[0].arn
}

resource "helm_release" "aws_lbc" {
  count      = var.enable_aws_lbc ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.17.1"

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    }
  ]

  lifecycle {
    precondition {
      condition     = !var.enable_aws_lbc || var.vpc_id != ""
      error_message = "vpc_id is required when enable_aws_lbc is true."
    }
  }

  depends_on = [helm_release.cluster_autoscaler]
}

# ==============================================================================
# 7. Nginx Ingress Controller
# ==============================================================================
resource "helm_release" "nginx_ingress" {
  count            = var.enable_nginx_ingress ? 1 : 0
  name             = "external"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress"
  create_namespace = true
  version          = "4.14.2"

  values = [file("${path.module}/values/nginx-ingress.yaml")]

  lifecycle {
    precondition {
      condition     = !var.enable_nginx_ingress || var.enable_aws_lbc
      error_message = "enable_aws_lbc must be true when enable_nginx_ingress is true (NLB is provisioned by LBC)."
    }
  }

  depends_on = [helm_release.aws_lbc]
}

# ==============================================================================
# 8. Cert Manager
# ==============================================================================
resource "helm_release" "cert_manager" {
  count            = var.enable_cert_manager ? 1 : 0
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = "v1.19.2"

  set = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]

  lifecycle {
    precondition {
      condition     = !var.enable_cert_manager || var.enable_nginx_ingress
      error_message = "enable_nginx_ingress must be true when enable_cert_manager is true."
    }
  }

  depends_on = [helm_release.nginx_ingress]
}

# ==============================================================================
# 9. External Secrets Operator
# ==============================================================================
data "aws_caller_identity" "current" {
  count = var.enable_external_secrets ? 1 : 0
}

data "aws_iam_policy_document" "external_secrets_assume" {
  count = var.enable_external_secrets && var.enable_oidc_provider ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks[0].arn]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  count              = var.enable_external_secrets ? 1 : 0
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume[0].json

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-external-secrets"
    Component = "eks-addons"
  })
}

resource "aws_iam_policy" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0
  name  = "${var.cluster_name}-external-secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current[0].account_id}:secret:${var.external_secrets_allowed_secrets_path}"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Component = "eks-addons"
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  count      = var.enable_external_secrets ? 1 : 0
  policy_arn = aws_iam_policy.external_secrets[0].arn
  role       = aws_iam_role.external_secrets[0].name
}

resource "helm_release" "external_secrets" {
  count            = var.enable_external_secrets ? 1 : 0
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  version          = "1.3.2"

  set = [
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-secrets-sa"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_secrets[0].arn
    }
  ]

  lifecycle {
    precondition {
      condition     = var.enable_oidc_provider
      error_message = "enable_oidc_provider must be true when enable_external_secrets is true (IRSA required)."
    }
  }

  depends_on = [
    aws_iam_role.external_secrets,
  helm_release.aws_lbc]
}
