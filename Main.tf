terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
#configure the aws provider
provider "aws" {
  region = var.rg_name
}
# Create a VPC
resource "aws_vpc" "Avpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "Avpc"
  }
}
# creating subnet1
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.Avpc.id
  cidr_block = var.subnet1_cidr
  availability_zone = var.subnet1_az
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-1"
  }
}
# Creating subnet2
resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.Avpc.id
  cidr_block = var.subnet2_cidr
  availability_zone = var.subnet2_az
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-2"
  }
}
resource "aws_subnet" "subnet3" {
  vpc_id     = aws_vpc.Avpc.id
  cidr_block = var.subnet3_cidr
  availability_zone = var.subnet3_az
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-3"
  }
}
# Create and attach IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.Avpc.id

  tags = {
    Name = "gw"
  }
}
# Creating a Route table for public subnets
resource "aws_route_table" "pubrtable" {
  vpc_id = aws_vpc.Avpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "pubrtable"
  }
}
resource "aws_route_table_association" "pubrtbassociation1" {
  subnet_id         = aws_subnet.subnet1.id
  route_table_id = aws_route_table.pubrtable.id
}
resource "aws_route_table_association" "pubrtbassociation2" {
  subnet_id         = aws_subnet.subnet3.id
  route_table_id = aws_route_table.pubrtable.id
}
# Creating a Route table for private subnets
resource "aws_route_table" "pvtrtable" {
  vpc_id = aws_vpc.Avpc.id

  tags = {
    Name = "pvtrtable"
  }
}
resource "aws_route_table_association" "pvtrtassociation" {
  subnet_id         = aws_subnet.subnet2.id
  route_table_id = aws_route_table.pvtrtable.id
}
#Creating security groups
resource "aws_security_group" "mysg" {
  name        = "mysg"
  description = "Allow ssh inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.Avpc.id
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mysg"
  }
}
# addig port 80 to allow inbound http traffic
resource "aws_security_group_rule" "httptrf" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.mysg.id
}
# Creating Key pair for Ec2
resource "aws_key_pair" "mkey" {
  key_name   = var.aws_keypair
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCrX/oH9jwHR3fv3pFsH8C2LgWiCBKMllcC60+kBpEfHsEtJ7BEHJQfcssW1vfKr+VyztUlGhgU4sSN9S5YpknQnPLey+KNewvswmtzXKx9Fb4viw6jmlVl5cWywZgusMXUllshqWn6s/WN9QYHm/QQ31fAys3u6BleTYonjrvyzWy8P8LrbRbEzxxI+dlDQSZU/jlDU0fUFwyIKgP/J8NhSwfC05+mS0DqbYLQfUZfvUD3UAP5fVfkeI/RA4UHijB8qY+XmO/aL+j8vEXtbP+5NUshxS+u/SuAzHc0h+5kOWkmWTHVBcCL/VAqMgmo21Yd8RYuoTUCsUNH8O3QlPTEbSq6ckBjNN71OgS1n2/j7DkwAp+DuOyU9v3p+zR5Dw+VPuBWQfnvQdQ46mBkZlybEbhk2X5GwfYzjFF4zWwhxeT1zH2i+V3yUjRCGlrLBa3tUdOnbwfgPIjiqNNTZtutN2LHAHFw3zc47X/trqAZFvpY4N3JflyuFgnbqOwCBl0= root@webserver-1"
}
#creating an Instance
resource  "aws_instance" "ahserver" {
  ami = var.aws_ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.mysg.id]
  key_name = var.aws_keypair
  user_data = <<-EOF
                #!/bin/bash
                yum install httpd git -y
                systemctl start httpd
                systemctl enable httpd
				git clone https://github.com/keyspaceits/sampleweb.git /var/www/html
                EOF
  tags = {
   Name = "ahserver"
   }
 }
output "ec2_instance_ip" {
 value = aws_instance.ahserver.public_ip
 description = "the public ip of the ahserver instance"
}
