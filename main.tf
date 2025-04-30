provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { 
    Name = "mia-vpc"
    }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { 
    Name = "mia-igw" 
    }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = { 
    Name = "public-subnet-1" 
    }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
  tags = { 
    Name = "public-subnet-2" 
    }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"
  tags = { 
    Name = "private-subnet-1" 
    }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"
  tags = { 
    Name = "private-subnet-2" 
    }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags = { 
    Name = "public-rt" 
    }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "nat_sg" {
  name        = "nat-sg"
  description = "Allow SSH, HTTP, and all traffic outbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ALL Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nat_instance" {
  ami                    = var.nat_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet_1.id
  associate_public_ip_address = true
  key_name               = var.key_name
  source_dest_check      = false
  vpc_security_group_ids = [aws_security_group.nat_sg.id]
  tags = { Name = "nat-instance" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "private-rt" }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat_instance.primary_network_interface_id

  depends_on = [aws_instance.nat_instance]
}

resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "private_instance_1" {
  ami                    = var.app_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_1.id
  associate_public_ip_address = false
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Hello from Private EC2</h1>" > /var/www/html/index.html
  EOF

  tags = { Name = "private-ec2-1" }
}

resource "aws_instance" "private_instance_2" {
  ami                    = var.app_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_2.id
  associate_public_ip_address = false
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>Hello from Private EC2</h1>" > /var/www/html/index.html
  EOF

  tags = { Name = "private-ec2-2" }
}

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.private_sg.id]
  subnets            = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "app_tg_attachment_1" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.private_instance_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app_tg_attachment_2" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.private_instance_2.id
  port             = 80
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}