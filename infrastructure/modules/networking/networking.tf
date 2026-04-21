data "aws_availability_zones" "available_zones" {
  state = "available"
}

data "aws_availability_zones" "apigw_zones" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
  exclude_zone_ids = ["use1-az3"]
}

resource "aws_vpc" "appvpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = var.vpc_name
    Environment = var.environment_val
  }
}

resource "aws_internet_gateway" "app_gw" {
  vpc_id = resource.aws_vpc.appvpc.id

  tags = {
    Name        = var.app_gateway_name
    Environment = var.environment_val
  }

}

# Create a public route table
resource "aws_route_table" "app_rt_public" {
  vpc_id = resource.aws_vpc.appvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = resource.aws_internet_gateway.app_gw.id
  }

  tags = {
    Name        = "${var.environment_val}-public_route_table"
    Environment = var.environment_val
  }
}

# create  public subnets
resource "aws_subnet" "app_public" {
  count             = length(data.aws_availability_zones.available_zones.names)
  vpc_id            = resource.aws_vpc.appvpc.id
  cidr_block        = cidrsubnet(resource.aws_vpc.appvpc.cidr_block, 8, count.index + 8)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name        = "${var.environment_val}-public_subnet-${count.index}"
    Environment = var.environment_val
  }
}

# Associate the public route table with the public subnets
resource "aws_route_table_association" "public_subnet_association" {
  count          = length(aws_subnet.app_public)
  subnet_id      = element(aws_subnet.app_public.*.id, count.index)
  route_table_id = element(aws_route_table.app_rt_public.*.id, count.index)
}

# create private subnets  
resource "aws_subnet" "app_private" {
  count             = length(data.aws_availability_zones.available_zones.names)
  vpc_id            = resource.aws_vpc.appvpc.id
  cidr_block        = cidrsubnet(resource.aws_vpc.appvpc.cidr_block, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name        = "${var.environment_val}-private_subnet-${count.index}"
    Environment = var.environment_val
  }
}

# create eip for nat gateway
resource "aws_eip" "app_gateway" {
  count      = 1
  domain     = "vpc"
  depends_on = [aws_internet_gateway.app_gw]

  tags = {
    Name        = "${var.environment_val}-eip-${count.index}"
    Environment = var.environment_val
  }
}

# create nat gateway
resource "aws_nat_gateway" "app_nat_gateway" {
  count         = 1
  subnet_id     = element(aws_subnet.app_public.*.id, count.index)
  allocation_id = element(aws_eip.app_gateway.*.id, count.index)

  tags = {
    Name        = "${var.environment_val}-nat-gateway-${count.index}"
    Environment = var.environment_val
  }
}

# create private route table
resource "aws_route_table" "app_rt_private" {
  vpc_id = resource.aws_vpc.appvpc.id
  count  = 1
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.app_nat_gateway.*.id, count.index)
  }

  tags = {
    Name        = "${var.environment_val}-private_route_table"
    Environment = var.environment_val
  }
}

# Associate the private route table with the private subnets
resource "aws_route_table_association" "private_subnet_association" {
  count          = length(aws_subnet.app_private)
  subnet_id      = element(aws_subnet.app_private.*.id, count.index)
  route_table_id = element(aws_route_table.app_rt_private.*.id, count.index)
}

# create security group for ec2 instances or use by any app computes
resource "aws_security_group" "app_sg" {
  vpc_id      = resource.aws_vpc.appvpc.id
  description = "security group for any app computes"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 5006
    to_port         = 5006
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 5007
    to_port         = 5007
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.web_sg.id]
    }

  tags = {
    Name        = "${var.environment_val}-security-group"
    Environment = var.environment_val
    Application = "project-zero"
  }
}

# create security group for any web components
resource "aws_security_group" "web_sg" {
  vpc_id      = resource.aws_vpc.appvpc.id
  description = "security group for any web components"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
  }

  tags = {
    Name        = "${var.environment_val}-web-security-group"
    Environment = var.environment_val
    Application = "project-zero"
  }
}




resource "aws_lb" "app_svc_lb" {
  name               = "${var.environment_val}-app-svc-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = aws_subnet.app_private[*].id

  tags = {
    Name        = "${var.environment_val}-app-svc-lb"
    Environment = var.environment_val
    Application = "project-zero"
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_lb_target_group" "app_svc_lb_tg" {
  name        = "${var.environment_val}-app-svc-lb-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.appvpc.id
  target_type = "ip"
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = 3000
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200,302"
  }

  tags = {
    Name        = "${var.environment_val}-app-svc-lb-tg"
    Environment = var.environment_val
    Application = "project-zero"
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_lb_listener" "app_svc_lb_listener" {
  load_balancer_arn = aws_lb.app_svc_lb.id
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.app_svc_lb_tg.arn
        weight = 100
      }
    }
  }





  tags = {
    Name        = "${var.environment_val}-app-svc-lb-listener"
    Environment = var.environment_val
    Application = "project-zero"
  }
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}




