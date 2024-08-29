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