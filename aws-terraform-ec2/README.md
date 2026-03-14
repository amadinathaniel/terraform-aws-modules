# terraform-aws-ec2

Terraform module to provision EC2 instances using Launch Templates and Auto Scaling Groups, with an IAM role, security group, and optional Elastic IP.

## Features

- **Launch Template** with configurable AMI, instance type, user data, key pair, root volume, and IMDSv2 enforcement
- **Auto Scaling Group** with rolling instance refresh, health checks, and optional target group attachment
- Dedicated security group with configurable ingress rules and all-outbound egress
- Optional IAM role with SSM managed policy and instance profile
- Optional Elastic IP for single-instance use cases
- Tag propagation to instances and volumes via launch template tag specifications

## Usage

```hcl
module "ec2" {
  source = "./terraform-aws-modules/aws-terraform-ec2"

  instance_name               = "teleios-nate-dev-web"
  ami_id                      = "ami-0abcdef1234567890"
  instance_type               = "t3.micro"
  subnet_ids                  = values(module.vpc.public_subnet_ids)
  vpc_id                      = module.vpc.vpc_id
  associate_public_ip_address = true
  root_volume_size            = 20
  iam_role_enabled            = true
  ssm_managed                 = true

  desired_capacity = 2
  min_size         = 1
  max_size         = 4

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF

  ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTP"
    }
  }

  common_tags = var.common_tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| instance_name | Name for LT, ASG, and resources | string | - | yes |
| ami_id | AMI ID | string | - | yes |
| instance_type | EC2 instance type | string | - | yes |
| subnet_ids | Subnet IDs for the ASG | list(string) | - | yes |
| vpc_id | VPC ID for the security group | string | - | yes |
| user_data | User data script (auto base64-encoded) | string | null | no |
| key_name | SSH key pair name | string | null | no |
| desired_capacity | Desired ASG size | number | 1 | no |
| min_size | Minimum ASG size | number | 1 | no |
| max_size | Maximum ASG size | number | 1 | no |
| health_check_type | ASG health check (EC2/ELB) | string | "EC2" | no |
| target_group_arns | ALB target group ARNs | list(string) | [] | no |
| ingress_rules | Map of SG ingress rules | map(object) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| launch_template_id | Launch template ID |
| autoscaling_group_id | ASG ID |
| autoscaling_group_name | ASG name |
| security_group_id | Instance security group ID |
| iam_role_arn | IAM role ARN |
