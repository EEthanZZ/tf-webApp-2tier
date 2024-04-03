resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}
#public subnets
resource "aws_subnet" "public_subnets" {
  vpc_id            = aws_vpc.main.id
  count             = 2
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "private_subnet_${count.index}"
  }
}


#private subnet
resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.main.id
  count             = 2
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "public_subnet_${count.index}"
  }
}

#gateway & route table
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

# Associate the public subnets with the public route table
resource "aws_route_table_association" "public_route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  count  = 2
}

resource "aws_nat_gateway" "nat" {
  count         = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  count  = 2
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
}

# Associate the private subnets with the private route table
resource "aws_route_table_association" "private_route_table_association" {
  count          = 2
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}
