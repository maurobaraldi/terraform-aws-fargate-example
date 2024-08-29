resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "ritual-roast-vpc"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "rr-public-subnet${count.index + 1}-${element(var.azs, count.index)}"
  }
}

resource "aws_subnet" "application_subnets" {
  count             = length(var.application_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.application_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "rr-app-subnet${count.index + 1}-${element(var.azs, count.index)}"
  }
}

resource "aws_subnet" "database_subnets" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.database_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "rr-data-subnet${count.index + 1}-${element(var.azs, count.index)}"
  }
}

# Internet Gateway Resources
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rr-igw"
  }

  depends_on = [
    aws_vpc.main,
    aws_subnet.public_subnets,
  ]
}

resource "aws_route_table" "route_table_igw_pub" {
  vpc_id = aws_vpc.main.id

  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = aws_internet_gateway.internet_gateway.id
  # }

  tags = {
    Name = "rr-route-table-igw-pub"
  }

  depends_on = [
    aws_internet_gateway.internet_gateway
  ]
}

resource "aws_route" "public_internet_igw_route" {
  route_table_id         = aws_route_table.route_table_igw_pub.id
  gateway_id             = aws_internet_gateway.internet_gateway.id
  destination_cidr_block = "0.0.0.0/0"

  depends_on = [
    aws_route_table.route_table_igw_pub
  ]
}

resource "aws_route_table_association" "route_igw_pub" {
  count          = length(var.application_subnet_cidrs)
  route_table_id = aws_route_table.route_table_igw_pub.id
  subnet_id      = aws_subnet.public_subnets[count.index].id

  depends_on = [
    aws_route.public_internet_igw_route
  ]
}