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

# NAT Gateway Resources
# You must define the Elastic IP in NAT Gateway, so define it first
resource "aws_eip" "elastic_ip_nat_gateway_a" {
  domain   = "vpc"

  tags     = {
    Name = "rr-eip-ngw-pub-a"
  }
}

resource "aws_nat_gateway" "nat_gateway_pub_a" {
  subnet_id     = aws_subnet.public_subnets[0].id
  allocation_id = aws_eip.elastic_ip_nat_gateway_a.id

  tags          = {
    Name = "rr-ngw-pub-a"
  }

  depends_on    = [
    aws_internet_gateway.internet_gateway
  ]
}

resource "aws_eip" "elastic_ip_nat_gateway_b" {
  domain   = "vpc"
  tags     = {
    Name = "rr-eip-ngw-pub-b"
  }
}

resource "aws_nat_gateway" "nat_gateway_pub_b" {
  subnet_id     = aws_subnet.public_subnets[1].id
  allocation_id = aws_eip.elastic_ip_nat_gateway_b.id

  tags          = {
    Name = "rr-ngw-pub-b"
  }

  depends_on    = [
    aws_internet_gateway.internet_gateway
  ]
}

# Routing table for private subnet in Availability - Zone A
resource "aws_route_table" "route_table_private_a" {
  vpc_id = aws_vpc.main.id
  tags   = {
    Name = "rr-rt-priv-a"
  }
}

# Route Access to the Internet through NAT - Zone A
resource "aws_route" "route_app_sn_a_ngw_a" {
  route_table_id         = aws_route_table.route_table_private_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway_pub_a.id
}

# Routing Table Association for Subnet application_subnets - Zone A
resource "aws_route_table_association" "route_app_sn_ngw_a" {
  subnet_id      = aws_subnet.application_subnets[0].id
  route_table_id = aws_route_table.route_table_private_a.id
}

# Routing table for private subnet in Availability - Zone B
resource "aws_route_table" "route_table_private_b" {
  vpc_id = aws_vpc.main.id
  tags   = {
    Name = "rr-rt-priv-b"
  }
}

# Route Access to the Internet through NAT - Zone B
resource "aws_route" "route_app_sn_a_ngw_b" {
  route_table_id         = aws_route_table.route_table_private_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway_pub_b.id
}

# Routing Table Association for Subnet application_subnets - Zone B
resource "aws_route_table_association" "route_app_sn_ngw_b" {
  subnet_id      = aws_subnet.application_subnets[1].id
  route_table_id = aws_route_table.route_table_private_b.id
}