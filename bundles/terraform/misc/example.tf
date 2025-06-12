# Terraform configuration example
# This file demonstrates various Terraform/HCL syntax elements

# Configure the required providers
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "terraform-example"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "server_config" {
  description = "Server configuration"
  type = object({
    instance_type = string
    disk_size     = number
    tags          = map(string)
  })
  default = {
    instance_type = "t3.micro"
    disk_size     = 20
    tags = {
      Type = "web-server"
    }
  }
}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Timestamp   = timestamp()
  }
  
  server_name = "${var.environment}-web-server"
  
  # Complex expressions
  instance_names = [
    for i in range(var.instance_count) : "${local.server_name}-${i + 1}"
  ]
  
  # Conditional logic
  monitoring_config = var.enable_monitoring ? {
    detailed_monitoring = true
    cloudwatch_logs    = true
  } : {
    detailed_monitoring = false
    cloudwatch_logs    = false
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Random resource for demonstration
resource "random_pet" "server" {
  length = 2
}

# VPC and networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "${var.environment}-vpc"
  })
}

resource "aws_subnet" "public" {
  count = min(length(data.aws_availability_zones.available.names), 2)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${var.environment}-igw"
  })
}

# Security group
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web-"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.environment}-web-sg"
  })
}

# EC2 instances
resource "aws_instance" "web" {
  count = var.instance_count
  
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.server_config.instance_type
  subnet_id              = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids = [aws_security_group.web.id]
  
  root_block_device {
    volume_type = "gp3"
    volume_size = var.server_config.disk_size
    encrypted   = true
  }
  
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Create a simple index page
    cat > /var/www/html/index.html <<HTML
    <html>
    <head><title>Server ${count.index + 1}</title></head>
    <body>
      <h1>Hello from ${local.instance_names[count.index]}!</h1>
      <p>Instance ID: \$(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
      <p>Environment: ${var.environment}</p>
    </body>
    </html>
HTML
  EOF
  
  tags = merge(
    local.common_tags,
    var.server_config.tags,
    {
      Name = local.instance_names[count.index]
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}

# Load balancer (using for_each)
resource "aws_lb" "main" {
  for_each = var.enable_monitoring ? { "main" = true } : {}
  
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id
  
  enable_deletion_protection = false
  
  tags = merge(local.common_tags, {
    Name = "${var.environment}-alb"
  })
}

# Module usage
module "database" {
  source = "./modules/rds"
  
  environment    = var.environment
  vpc_id         = aws_vpc.main.id
  subnet_ids     = aws_subnet.public[*].id
  instance_class = "db.t3.micro"
  
  tags = local.common_tags
}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of the instances"
  value       = aws_instance.web[*].public_ip
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = try(aws_lb.main["main"].dns_name, null)
}

output "server_urls" {
  description = "URLs to access the servers"
  value = [
    for ip in aws_instance.web[*].public_ip : "http://${ip}"
  ]
}

output "environment_info" {
  description = "Environment information"
  value = {
    environment     = var.environment
    region         = var.aws_region
    instance_count = var.instance_count
    monitoring     = var.enable_monitoring
    server_names   = local.instance_names
  }
  sensitive = false
}

# Complex heredoc example
resource "aws_s3_bucket_policy" "example" {
  bucket = "my-terraform-bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::my-terraform-bucket/*"
        Condition = {
          StringEquals = {
            "aws:SourceIp" = ["203.0.113.0/24"]
          }
        }
      }
    ]
  })
}

# Terraform functions demonstration
locals {
  # String functions
  uppercase_env = upper(var.environment)
  formatted_name = format("%s-%s-%s", var.environment, "app", formatdate("YYYY-MM-DD", timestamp()))
  
  # Collection functions
  unique_zones = distinct(data.aws_availability_zones.available.names)
  zone_count = length(local.unique_zones)
  
  # Conditional expressions
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  
  # Try function for error handling
  safe_config = try(var.server_config.advanced.monitoring, false)
}

# Moved block example (for state management)
moved {
  from = aws_instance.old_web
  to   = aws_instance.web
}

# Check block example (for validation)
check "health_check" {
  data "http" "example" {
    url = "https://checkpoint-api.hashicorp.com/v1/check/terraform"
  }
  
  assert {
    condition     = data.http.example.status_code == 200
    error_message = "Health check failed"
  }
}

# ============================================================================
# Function styling examples
# Examples demonstrating function styling vs. variable/attribute styling
# ============================================================================

# Variables with names that match builtin functions
# These should be styled as identifiers/keys, not functions
variable "format" {
  description = "A variable named after the format function"
  type        = string
  default     = "default-format"
}

variable "timestamp" {
  description = "A variable named after the timestamp function"
  type        = string
  default     = "default-timestamp"
}

# Resource with attributes that match builtin functions
resource "aws_instance" "example" {
  # These attributes should be styled as keys, not functions
  join        = "attribute-value"
  upper       = "attribute-value"
  lower       = "attribute-value"
}

# Local values using function calls
# The function names should be styled as functions
locals {
  # Function calls - should be styled as functions
  current_time = timestamp()
  formatted_string = format("%s-%s", "prefix", "suffix")
  joined_list = join("-", ["a", "b", "c"])
  
  # Variable references - should not be styled as functions
  format_var = var.format
  timestamp_var = var.timestamp
  
  # Interpolation with function calls
  interpolated = "The time is ${timestamp()} and formatted as ${format("%s", "test")}"
  
  # Interpolation with variable references
  interpolated_vars = "Using variables: ${var.format} and ${var.timestamp}"
}

# Output demonstrating both function calls and variable references
output "test_output" {
  value = {
    # Function calls
    current_time = timestamp()
    formatted = format("%s", local.format_var)
    
    # Variable references
    format_value = var.format
    timestamp_value = var.timestamp
    
    # Resource attribute references
    join_attr = aws_instance.example.join
    upper_attr = aws_instance.example.upper
  }
}