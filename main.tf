provider "aws" {
  region = "us-east-1"
}

# VPC for VPN Test
resource "aws_vpc" "vpn_test_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPN-Test-VPC"
  }
}

# Public subnet for VPN server
resource "aws_subnet" "vpn_test_public_subnet" {
  vpc_id                  = aws_vpc.vpn_test_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "VPN-Test-Public-Subnet"
  }
}

# Private subnet for internal resources (accessible only via VPN)
resource "aws_subnet" "vpn_test_private_subnet" {
  vpc_id            = aws_vpc.vpn_test_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "VPN-Test-Private-Subnet"
  }
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "vpn_test_internet_gateway" {
  vpc_id = aws_vpc.vpn_test_vpc.id

  tags = {
    Name = "VPN-Test-Internet-Gateway"
  }
}

# Route table for public subnet (for internet access)
resource "aws_route_table" "vpn_test_public_route_table" {
  vpc_id = aws_vpc.vpn_test_vpc.id

  tags = {
    Name = "VPN-Test-Public-Route-Table"
  }
}

resource "aws_route" "vpn_test_public_route" {
  route_table_id         = aws_route_table.vpn_test_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpn_test_internet_gateway.id
}

resource "aws_route_table_association" "vpn_test_public_route_table_assoc" {
  subnet_id      = aws_subnet.vpn_test_public_subnet.id
  route_table_id = aws_route_table.vpn_test_public_route_table.id
}

# Security Group for VPN Server
resource "aws_security_group" "vpn_test_openvpn_sg" {
  vpc_id = aws_vpc.vpn_test_vpc.id

  ingress {
    description = "Allow VPN access"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow OpenVPN Admin UI access"
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "VPN-Test-OpenVPN-SG"
  }
}

# Private route table (for private subnet with no direct internet access)
resource "aws_route_table" "vpn_test_private_route_table" {
  vpc_id = aws_vpc.vpn_test_vpc.id

  tags = {
    Name = "VPN-Test-Private-Route-Table"
  }
}

resource "aws_route_table_association" "vpn_test_private_route_table_assoc" {
  subnet_id      = aws_subnet.vpn_test_private_subnet.id
  route_table_id = aws_route_table.vpn_test_private_route_table.id
}

# EC2 Instance for OpenVPN Server (Using Free Tier Instance Type t2.micro)
resource "aws_instance" "vpn_test_openvpn_instance" {
  ami                         = "ami-02612c926201def10" # OpenVPN Access Server Community Image
  instance_type               = "t2.micro"              # Free tier eligible instance
  subnet_id                   = aws_subnet.vpn_test_public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.vpn_test_openvpn_sg.id] # Referencing the SG by ID

  tags = {
    Name = "VPN-Test-OpenVPN-Server"
  }
}

# EC2 Instance in Private Subnet for Testing
resource "aws_instance" "vpn_test_private_instance" {
  ami                         = "ami-0ae8f15ae66fe8cda" # Amazon Linux 2023
  instance_type               = "t2.micro"              # Free tier eligible instance
  subnet_id                   = aws_subnet.vpn_test_private_subnet.id
  associate_public_ip_address = false                                       # No public IP
  vpc_security_group_ids      = [aws_security_group.vpn_test_openvpn_sg.id] # Use the same security group for simplicity

  tags = {
    Name = "VPN-Test-Private-Instance"
  }
}

output "vpn_test_vpc_id" {
  value       = aws_vpc.vpn_test_vpc.id
  description = "The ID of the VPC for the VPN test."
}

output "vpn_test_public_subnet_id" {
  value       = aws_subnet.vpn_test_public_subnet.id
  description = "The ID of the public subnet for the VPN test."
}

output "vpn_test_private_subnet_id" {
  value       = aws_subnet.vpn_test_private_subnet.id
  description = "The ID of the private subnet for the VPN test."
}

output "vpn_test_security_group_id" {
  value       = aws_security_group.vpn_test_openvpn_sg.id
  description = "The ID of the security group for the OpenVPN server."
}

output "vpn_test_openvpn_instance_public_ip" {
  value       = aws_instance.vpn_test_openvpn_instance.public_ip
  description = "The public IP address of the OpenVPN server."
}

output "vpn_test_openvpn_instance_id" {
  value       = aws_instance.vpn_test_openvpn_instance.id
  description = "The ID of the OpenVPN EC2 instance."
}

output "vpn_test_private_instance_id" {
  value       = aws_instance.vpn_test_private_instance.id
  description = "The ID of the private EC2 instance."
}
