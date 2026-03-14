# ==============================================================================
# IAM - Cluster Role
# ==============================================================================
data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-cluster-role"
    Component = "eks"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_amazon_eks_cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_amazon_eks_vpc_resource_controller" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ==============================================================================
# IAM - Node Role
# ==============================================================================
data "aws_iam_policy_document" "node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-node-role"
    Component = "eks"
  })
}

resource "aws_iam_role_policy_attachment" "node_worker_node" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_read_only" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ==============================================================================
# Security Group - Cluster
# ==============================================================================
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for the EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-cluster-sg"
    Component = "eks"
  })
}

resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ==============================================================================
# Security Group - Nodes
# ==============================================================================
resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-node-sg"
    Component = "eks"
  })
}

resource "aws_vpc_security_group_egress_rule" "node_all" {
  security_group_id = aws_security_group.node.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Node-to-node communication
resource "aws_vpc_security_group_ingress_rule" "node_self" {
  security_group_id            = aws_security_group.node.id
  description                  = "Allow nodes to communicate with each other"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.node.id
}

# Cluster to nodes (HTTPS)
resource "aws_vpc_security_group_ingress_rule" "node_from_cluster_api" {
  security_group_id            = aws_security_group.node.id
  description                  = "Allow cluster API server to communicate with nodes"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.cluster.id
}

# Cluster to nodes (kubelet)
resource "aws_vpc_security_group_ingress_rule" "node_from_cluster_kubelet" {
  security_group_id            = aws_security_group.node.id
  description                  = "Allow cluster API server to reach kubelet on nodes"
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.cluster.id
}

# Nodes to cluster (HTTPS)
resource "aws_vpc_security_group_ingress_rule" "cluster_from_nodes" {
  security_group_id            = aws_security_group.cluster.id
  description                  = "Allow nodes to communicate with cluster API"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.node.id
}

# ==============================================================================
# EKS Cluster
# ==============================================================================
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = var.cluster_log_types

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  tags = merge(var.common_tags, {
    Name      = var.cluster_name
    Component = "eks"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.cluster_amazon_eks_vpc_resource_controller,
  ]
}

# ==============================================================================
# EKS Managed Node Groups
# ==============================================================================
resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type
  disk_size       = each.value.disk_size
  labels          = each.value.labels

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  update_config {
    max_unavailable = 1
  }

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-${each.key}"
    Component = "eks"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_node,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr_read_only,
    aws_iam_role_policy_attachment.node_ssm,
  ]
}

# ==============================================================================
# EKS Addons
# ==============================================================================
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Component = "eks"
  })
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Component = "eks"
  })

  depends_on = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = merge(var.common_tags, {
    Component = "eks"
  })
}

# ==============================================================================
# Application Load Balancer (optional)
# ==============================================================================
resource "aws_security_group" "alb" {
  count       = var.enable_alb ? 1 : 0
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for the EKS ALB"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-alb-sg"
    Component = "eks"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count             = var.enable_alb ? 1 : 0
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTP traffic"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count             = var.enable_alb ? 1 : 0
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTPS traffic"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  count             = var.enable_alb ? 1 : 0
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "node_from_alb" {
  count                        = var.enable_alb ? 1 : 0
  security_group_id            = aws_security_group.node.id
  description                  = "Allow ALB to reach nodes on NodePort range"
  from_port                    = 30000
  to_port                      = 32767
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb[0].id
}

resource "aws_lb" "this" {
  count              = var.enable_alb ? 1 : 0
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.public_subnet_ids

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-alb"
    Component = "eks"
  })
}

resource "aws_lb_target_group" "this" {
  count       = var.enable_alb ? 1 : 0
  name        = "${var.cluster_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = merge(var.common_tags, {
    Name      = "${var.cluster_name}-tg"
    Component = "eks"
  })
}

resource "aws_lb_listener" "http" {
  count             = var.enable_alb ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  tags = merge(var.common_tags, {
    Component = "eks"
  })
}
