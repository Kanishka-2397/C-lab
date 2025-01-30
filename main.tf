provider "aws" {}

# VPC Creation
resource "aws_vpc" "tf_vpc1" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "tf_vpc1"
  }
}

# Subnets
resource "aws_subnet" "tf_sub-1" {
  vpc_id            = aws_vpc.tf_vpc1.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Ensure public IP for accessibility
  tags = {
    Name = "tf_sub-1"
  }
}

resource "aws_subnet" "tf_sub-2" {
  vpc_id            = aws_vpc.tf_vpc1.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "tf_sub-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw1" {
  vpc_id = aws_vpc.tf_vpc1.id
  tags = {
    Name = "igw1"
  }
}

# Public Route Table
resource "aws_route_table" "tf_route1" {
  vpc_id = aws_vpc.tf_vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw1.id
  }

  tags = {
    Name = "tf_route1"
  }
}



# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "tf_sub2_association" {
  subnet_id      = aws_subnet.tf_sub-2.id
  route_table_id = aws_route_table.tf_route2.id
}

# Security Group
resource "aws_security_group" "tf_sg1" {
  vpc_id = aws_vpc.tf_vpc1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH (only for testing, restrict later)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "tf_sg1"
  }
}

# Key Pair
resource "aws_key_pair" "tf_keys" {
  key_name   = "devops"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzjX8fSdjO..."
}

# EC2 Instance
resource "aws_instance" "server-1" {
  ami                    = data.aws_ami.centOs1.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.tf_keys.key_name
  subnet_id              = aws_subnet.tf_sub-1.id
  vpc_security_group_ids = [aws_security_group.tf_sg1.id]
  availability_zone      = "us-east-1a"

  tags = {
    Name = "server-1"
  }
}

# Data Source for Amazon Linux 2 AMI
data "aws_ami" "centOs1" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]  # Fetch latest Amazon Linux 2
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
