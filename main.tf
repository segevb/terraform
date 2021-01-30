 # provider declaration - hashicorp/aws
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
     }
  }
}

 # Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"  # Frankfurt region
  access_key = ""
  secret_key = ""
}

 # Create a VPC
resource "aws_vpc" "devops_2020" {
  cidr_block = "10.0.0.0/16"
}

 # Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.devops_2020.id
}

 # Create Custom Route Table
resource "aws_route_table" "devops_rt1" {
  vpc_id = aws_vpc.devops_2020.id

 # Create routing rules to my internet gateway
 route {
     cidr_block = "0.0.0.0/0" # IPv4
     gateway_id = aws_internet_gateway.gw.id
 }

  route {
     ipv6_cidr_block = "::/0" #IPv6
     gateway_id = aws_internet_gateway.gw.id
 }

 tags = {
   "Name" = "devops_2020"
  }

}

# Create network Subnet
resource "aws_subnet" "devops_subnet-01" {
    vpc_id = aws_vpc.devops_2020.id
    cidr_block = "10.0.1.0/24"
 # create the subnet in the same availability zone of my new VPC
    availability_zone = "eu-central-1a"

    tags = {
      Name = "devops_subnet-01"
    }
}

 # Associate Route table with subnet
resource "aws_route_table_association" "route_table_1" {
 subnet_id = aws_subnet.devops_subnet-01.id
 route_table_id = aws_route_table.devops_rt1.id
}

 # Create securiry group
resource "aws_security_group" "allow_web" {
  name = "allow_web_traffic"
  description = "Allow inbound web traffic"
  vpc_id = aws_vpc.devops_2020.id

 # incoming traffic roule
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

 # outgoing traffic roule
  egress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All networks allowed"
 # all ports
    from_port = 0
    to_port = 0
 # all protocols
    protocol = "-1"
  }

  tags = {
    "Name" = "DevOps-2020"
  }
}

 # Create new network interface
resource "aws_network_interface" "web-server-nic" {
  subnet_id =  aws_subnet.devops_subnet-01.id
  private_ips = ["10.0.1.10"]
  security_groups = [ aws_security_group.allow_web.id ]
}

 # Create new Elastic IP (public ip)
resource "aws_eip" "web_eip" {
    vpc = true
 # associate public ip with nic
    network_interface = aws_network_interface.web-server-nic.id
    associate_with_private_ip = "10.0.1.10"
    depends_on = [ aws_internet_gateway.gw ]
}

 # Printout the server public ip
output "server_public_ip" {
  value = aws_eip.web_eip.public_ip
}

 # Create a new ubuntu instance
resource "aws_instance" "web_server_instance" {
    ami = "ami-0502e817a62226e03"   # image id
    instance_type = "t2.micro"
    availability_zone = "eu-central-1a"
    key_name = "int2021"  # ssh key

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web-server-nic.id
    }
  tags = {
    "Name" = "Segev Web Server"
   }
}