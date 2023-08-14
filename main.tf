provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
        "Name" = "MyVPC"
        project = "SprintsProject"
    }
}

resource "aws_subnet" "my_subnet" {
    cidr_block = "10.0.0.0/24"
    vpc_id = aws_vpc.my_vpc.id
    map_public_ip_on_launch = true
    tags = {
        Name = "MySubnet"
    }
}

resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "MyInternetGateway"
    }
}

resource "aws_route_table" "my_route_table" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }

    tags = {
        Name = "MyRouteTable"
    }
}

resource "aws_route_table_association" "my_subnet_association" {
    subnet_id = aws_subnet.my_subnet.id
    route_table_id = aws_route_table.my_route_table.id
}

resource "aws_security_group" "my_security_group" {
    name        = "MySecurityGroup"
    description = "Allow HTTP and SSH traffic"
    vpc_id      = aws_vpc.my_vpc.id

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow incoming HTTPS connections"
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow incoming SSH connections"
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow incoming HTTP connections"
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "MySecurityGroup"
    }
}

data "aws_ami" "ubuntu" {
    most_recent = true
    owners      = ["amazon"]

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_instance" "my_instance" {
    ami                         = data.aws_ami.ubuntu.id
    instance_type               = "t2.micro"
    subnet_id                   = aws_subnet.my_subnet.id
    vpc_security_group_ids      = [aws_security_group.my_security_group.id]
    associate_public_ip_address = true
    source_dest_check           = false

    user_data = <<-EOF
        #!/bin/bash
        sudo apt update
        sudo apt install -y apache2
    EOF

    tags = {
        Name = "MyInstance"
    }
}
