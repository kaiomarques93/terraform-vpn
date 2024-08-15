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
  vpc_id            = aws_vpc.vpn_test_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

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

# Security Group for VPN Server (You will create the EC2 instance manually)
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

output "vpn_test_vpc_id" {
  value = aws_vpc.vpn_test_vpc.id
  description = "The ID of the VPC for the VPN test."
}

output "vpn_test_public_subnet_id" {
  value = aws_subnet.vpn_test_public_subnet.id
  description = "The ID of the public subnet for the VPN test."
}

output "vpn_test_private_subnet_id" {
  value = aws_subnet.vpn_test_private_subnet.id
  description = "The ID of the private subnet for the VPN test."
}

output "vpn_test_security_group_id" {
  value = aws_security_group.vpn_test_openvpn_sg.id
  description = "The ID of the security group for the OpenVPN server."
}
