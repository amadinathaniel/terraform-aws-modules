# ==============================================================================
# 1. Cluster Autoscaler
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
    Component = "helm-releases"
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
    Component = "helm-releases"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = aws_iam_role.cluster_autoscaler[0].name
}

resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  count           = var.enable_cluster_autoscaler ? 1 : 0
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
  version    = var.cluster_autoscaler_version

  set = [{
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
    },
    {
      name  = "autoDiscovery.clusterName"
      value = var.cluster_name
    },
    {
      name  = "awsRegion"
      value = var.aws_region
    }
  ]
}

# ==============================================================================
# 2. AWS Load Balancer Controller (optional)
# ==============================================================================
data "aws_iam_policy_document" "aws_lbc_assume" {
  count = var.enable_aws_lbc ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "aws_lbc" {
  count              = var.enable_aws_lbc ? 1 : 0
  name               = "${var.cluster_name}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc_assume[0].json

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-aws-lbc"
    Component = "helm-releases"
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
  count           = var.enable_aws_lbc ? 1 : 0
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
  version    = var.aws_lbc_version

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
}

# ==============================================================================
# 3. Nginx Ingress Controller
# ==============================================================================
resource "helm_release" "nginx_ingress" {
  count            = var.enable_nginx_ingress ? 1 : 0
  name             = "external"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress"
  create_namespace = true
  version          = var.nginx_ingress_version

  set = concat(
    [
      {
        name  = "controller.ingressClassResource.name"
        value = "external-nginx"
      },
      {
        name  = "controller.service.type"
        value = "LoadBalancer"
      },
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
        value = "internet-facing"
      },
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
        value = "true"
      }
    ],
    var.enable_aws_lbc ? [
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
        value = "external"
      },
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
        value = "ip"
      }
      ] : [
      {
        name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
        value = "nlb"
      }
    ]
  )

  depends_on = [helm_release.aws_lbc]
}

# ==============================================================================
# 4. Cert Manager
# ==============================================================================
resource "helm_release" "cert_manager" {
  count            = var.enable_cert_manager ? 1 : 0
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = var.cert_manager_version

  set = [
    {
      name  = "crds.enabled"
      value = "true"
    }
  ]

  depends_on = [helm_release.nginx_ingress]
}

# ==============================================================================
# 5. External Secrets Operator
# ==============================================================================
data "aws_caller_identity" "current" {
  count = var.enable_external_secrets ? 1 : 0
}

data "aws_iam_policy_document" "external_secrets_assume" {
  count = var.enable_external_secrets && var.oidc_provider_arn != "" ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets-sa"]
    }

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  count              = var.enable_external_secrets ? 1 : 0
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume[0].json

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-external-secrets"
    Component = "helm-releases"
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
    Component = "helm-releases"
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
  version          = var.external_secrets_version

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
      condition     = var.oidc_provider_arn != ""
      error_message = "oidc_provider_arn is required when enable_external_secrets is true (IRSA required)."
    }
  }

  depends_on = [
    aws_iam_role.external_secrets,
    helm_release.aws_lbc
  ]
}
