# terraform-aws-ec2

Terraform module to provision EC2 instances via Launch Templates with Auto Scaling Groups or as standalone instances, with IAM roles, security groups, and optional Elastic IP.

## Features

- Auto AMI lookup for Amazon Linux 2023 and Ubuntu 24.04 (or bring your own AMI)
- **ASG mode** (`use_asg = true`): Launch Template + Auto Scaling Group with rolling refresh
- **Standalone mode** (`use_asg = false`): Single EC2 instance directly
- Dedicated security group with configurable ingress rules
- Optional IAM role with SSM managed policy
- Optional Elastic IP for single-instance use cases
- User data support (auto base64-encoded for launch templates)
- IMDSv2 enforced, encrypted root volumes

## Usage

### ASG mode (default)
```hcl
module "ec2_web" {
  source = "../terraform-aws-modules/aws-terraform-ec2"

  instance_name               = "teleios-nate-dev-web"
  os_type                     = "amazon_linux_2023"
  instance_type               = "t3.micro"
  subnet_ids                  = ["subnet-abc123", "subnet-def456"]
  vpc_id                      = "vpc-123456"
  associate_public_ip_address = true
  root_volume_size            = 30
  desired_capacity            = 2
  min_size                    = 1
  max_size                    = 4

  ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTP"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTPS"
    }
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
  EOF

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### Standalone mode
```hcl
module "ec2_bastion" {
  source = "../terraform-aws-modules/aws-terraform-ec2"

  instance_name               = "teleios-nate-dev-bastion"
  os_type                     = "ubuntu"
  instance_type               = "t3.micro"
  subnet_ids                  = ["subnet-abc123"]
  vpc_id                      = "vpc-123456"
  use_asg                     = true
  associate_public_ip_address = true
  root_volume_size            = 30
  iam_role_enabled            = true
  ssm_managed                 = true
  min_size                    = 0
  max_size                    = 1

  ingress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow SSH"
    }
  }

  common_tags = {
    Project     = "e-commerce-infrastructure"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| instance_name | Name for all resources | string | - | yes |
| ami_id | Specific AMI ID (overrides os_type) | string | null | no |
| os_type | Auto AMI lookup (amazon_linux_2023 or ubuntu) | string | "amazon_linux_2023" | no |
| instance_type | EC2 instance type | string | - | yes |
| subnet_ids | Subnet IDs for ASG or standalone | list(string) | - | yes |
| vpc_id | VPC ID for security group | string | - | yes |
| use_asg | Create ASG (true) or standalone instance (false) | bool | true | no |
| associate_public_ip_address | Associate public IP | bool | - | yes |
| root_volume_size | Root volume size in GB | number | - | yes |
| root_volume_type | Root volume type | string | "gp3" | no |
| user_data | User data script | string | null | no |
| key_name | SSH key pair name | string | null | no |
| iam_role_enabled | Create IAM role and instance profile | bool | true | no |
| ssm_managed | Attach SSM policy to IAM role | bool | true | no |
| desired_capacity | Desired ASG size | number | 1 | no |
| min_size | Minimum ASG size | number | 0 | yes (if use_asg = "true") |
| max_size | Maximum ASG size | number | 1 | yes yes (if use_asg = "true") |
| health_check_type | ASG health check (EC2/ELB) | string | "EC2" | no |
| health_check_grace_period | Seconds before health checks start | number | 300 | no |
| target_group_arns | ALB target group ARNs | list(string) | [] | no |
| allocate_eip | Allocate Elastic IP | bool | false | no |
| ingress_rules | Map of SG ingress rules | map(object) | {} | no |
| additional_security_group_ids | Extra SG IDs to attach | list(string) | [] | no |
| common_tags | Common tags for all resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| launch_template_id | Launch template ID (ASG mode only) |
| launch_template_latest_version | Latest launch template version (ASG mode only) |
| autoscaling_group_id | ASG ID (ASG mode only) |
| autoscaling_group_name | ASG name (ASG mode only) |
| autoscaling_group_arn | ASG ARN (ASG mode only) |
| instance_id | Standalone instance ID (standalone mode only) |
| private_ip | Standalone instance private IP |
| public_ip | Standalone instance public IP |
| security_group_id | Security group ID |
| iam_role_arn | IAM role ARN |
| iam_instance_profile_name | Instance profile name |
| eip_public_ip | Elastic IP address |
