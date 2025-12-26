#VPC 
resource "aws_vpc" "eks_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "eks_vpc"  
    }
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.eks_vpc.id
    tags = {
        Name = "eks_igw"
    }
}

#Public Subnets
# 1
resource "aws_subnet" "public_1" {
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-west-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "eks_public_subnet_1"
    }
}

# 2
resource "aws_subnet" "public_2" {
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-west-1b"
    map_public_ip_on_launch = true
    tags = {
        Name = "eks_public_subnet_2"
    }
}

#Private Subnets
# 1
resource "aws_subnet" "private_1" {
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "eu-west-1a"
    tags = {
        Name = "eks_private_subnet_1"
    }
}

# 2
resource "aws_subnet" "private_2" {
    vpc_id = aws_vpc.eks_vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "eu-west-1b"
    tags = {
        Name = "eks_private_subnet_2"
    }
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
    tags = {
        Name = "eks_nat_eip"
    }
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public_1.id
    tags = {
        Name = "eks_nat_gateway"
    }
}

# Route Tables
# Public Route Table
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.eks_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
        Name = "eks_public_rt"
    }
}

resource "aws_route_table_association" "public_rt_assoc_1" {
    subnet_id = aws_subnet.public_1.id
    route_table_id = aws_route_table.public_rt.id
  
}

resource "aws_route_table_association" "public_rt_assoc_2" {
    subnet_id = aws_subnet.public_2.id
    route_table_id = aws_route_table.public_rt.id
}

# Private Route Table
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.eks_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
}
    tags = {
        Name = "eks_private_rt"
    }
}

resource "aws_route_table_association" "private_rt_assoc_1" {
    subnet_id = aws_subnet.private_1.id
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_assoc_2" {
    subnet_id = aws_subnet.private_2.id
    route_table_id = aws_route_table.private_rt.id
}





