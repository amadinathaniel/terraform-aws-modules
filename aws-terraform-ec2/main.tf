# ==============================================================================
# Local Values
# ==============================================================================
locals {
  resolved_ami_id = var.ami_id != null ? var.ami_id : (
    var.os_type == "ubuntu" ? data.aws_ami.ubuntu.id : data.aws_ami.amazon_linux_2023.id
  )
}

# ==============================================================================
# IAM Role & Instance Profile
# ==============================================================================
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count              = var.iam_role_enabled ? 1 : 0
  name               = "${var.instance_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.common_tags, {
    Name      = "${var.instance_name}-role"
    Component = "ec2"
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.iam_role_enabled && var.ssm_managed ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  count = var.iam_role_enabled ? 1 : 0
  name  = "${var.instance_name}-profile"
  role  = aws_iam_role.this[0].name

  tags = merge(var.common_tags, {
    Name      = "${var.instance_name}-profile"
    Component = "ec2"
  })
}

# ==============================================================================
# AMI Data Source
# ==============================================================================
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ==============================================================================
# Security Group
# ==============================================================================
resource "aws_security_group" "this" {
  name        = "${var.instance_name}-sg"
  description = "Security group for ${var.instance_name} instances"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name      = "${var.instance_name}-sg"
    Component = "ec2"
  })
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "custom" {
  for_each = var.ingress_rules

  security_group_id            = aws_security_group.this.id
  description                  = each.value.description
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.referenced_security_group_id
}

# ==============================================================================
# Launch Template
# ==============================================================================
resource "aws_launch_template" "this" {
  count       = var.use_asg ? 1 : 0
  name        = "${var.instance_name}-lt"
  description = "Launch template for ${var.instance_name}"
  image_id    = local.resolved_ami_id
  key_name    = var.key_name

  instance_type = var.instance_type

  iam_instance_profile {
    name = var.iam_role_enabled ? aws_iam_instance_profile.this[0].name : null
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = concat([aws_security_group.this.id], var.additional_security_group_ids)
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = var.user_data != null ? base64encode(var.user_data) : null

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name      = var.instance_name
      Component = "ec2"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.common_tags, {
      Name      = "${var.instance_name}-vol"
      Component = "ec2"
    })
  }

  tags = merge(var.common_tags, {
    Name      = "${var.instance_name}-lt"
    Component = "ec2"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ==============================================================================
# Auto Scaling Group
# ==============================================================================
resource "aws_autoscaling_group" "this" {
  count               = var.use_asg ? 1 : 0
  name                = "${var.instance_name}-asg"
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  target_group_arns         = var.target_group_arns

  launch_template {
    id      = aws_launch_template.this[0].id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(var.common_tags, {
      Name      = var.instance_name
      Component = "ec2"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
# ==============================================================================
# Standalone EC2 Instance (if not using ASG)
# ==============================================================================
resource "aws_instance" "this" {
  count                       = var.use_asg ? 0 : 1
  ami                         = local.resolved_ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[0]
  key_name                    = var.key_name
  vpc_security_group_ids      = concat([aws_security_group.this.id], var.additional_security_group_ids)
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile        = var.iam_role_enabled ? aws_iam_instance_profile.this[0].name : null
  user_data                   = var.user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
  }

  tags = merge(var.common_tags, {
    Name      = var.instance_name
    Component = "ec2"
  })
}

# ==============================================================================
# Elastic IP (conditional — for single-instance use cases)
# ==============================================================================
resource "aws_eip" "this" {
  count  = var.allocate_eip ? 1 : 0
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name      = "${var.instance_name}-eip"
    Component = "ec2"
  })
}
