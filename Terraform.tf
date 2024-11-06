terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "MYVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "MY-VPC"
  }
}

resource "aws_subnet" "PUBSUB" {
  vpc_id     = aws_vpc.MYVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "MY-PUBSUB"
  }
}

resource "aws_subnet" "PVTSUB" {
  vpc_id     = aws_vpc.MYVPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "MY-PVTSUB"
  }
}

resource "aws_internet_gateway" "MYIGW" {
  vpc_id = aws_vpc.MYVPC.id

  tags = {
    Name = "MY-VPC-IGW"
  }
}

resource "aws_route_table" "PUBRT" {
  vpc_id = aws_vpc.MYVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.MYIGW.id
  }

  tags = {
    Name = "MY-PUB-RT"
  }

}



resource "aws_route_table_association" "PUBRTASSOCIATE" {
  subnet_id      = aws_subnet.PUBSUB.id
  route_table_id = aws_route_table.PUBRT.id
}


resource "aws_eip" "MYEIP" {
  domain   = "vpc"
}


resource "aws_nat_gateway" "MY-NAT-GTW" {
  allocation_id = aws_eip.MYEIP.id
  subnet_id     = aws_subnet.PUBSUB.id

  tags = {
    Name = "MY-NAT"
  }
}


resource "aws_route_table" "PVTRT" {
  vpc_id = aws_vpc.MYVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.MY-NAT-GTW.id
  }

  tags = {
    Name = "MY-PVT-RT"
  }
}


resource "aws_route_table_association" "PVTRTASSOCIATE" {
  subnet_id      = aws_subnet.PVTSUB.id
  route_table_id = aws_route_table.PVTRT.id
}

provider "aws" {
  region = "ap-south-1" 
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.MYVPC.id 

  # Inbound Rules
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

 
  # Outbound Rules
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # -1 allows all protocols
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MY-VPC-SG"
  }
}

 resource "aws_instance" "instance1" {
    ami                        =    "ami-0dee22c13ea7a9a67"
    instance_type              =    "t2.micro"
    subnet_id                  =    aws_subnet.PUBSUB.id
    vpc_security_group_ids     =    [ aws_security_group.allow_all.id]
    key_name                    =    "SHELL"
    associate_public_ip_address = true

 }

  resource "aws_instance" "instance2" {
    ami                        =    "ami-0dee22c13ea7a9a67"
    instance_type              =    "t2.micro"
    subnet_id                  =    aws_subnet.PVTSUB.id
    vpc_security_group_ids     =    [ aws_security_group.allow_all.id]
    key_name                    =    "SHELL"

  }




