#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

# https://console.aws.amazon.com/vpc/home?#vpcs:

resource "aws_vpc" "rhombus-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = tomap({
    "Name"                                      = "${var.cluster_name}-vpc",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
    Environment                                 = var.app_environment
  })
}

# https://console.aws.amazon.com/vpc/home?#subnets:
resource "aws_subnet" "rhombus-subnet" {
  count                   = var.vpc-subnets
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.rhombus-vpc.id

  tags = tomap({
    "Name"                                      = "${var.cluster_name}-subnet-${count.index + 1}",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
    Environment                                 = var.app_environment
  })
}

# https://console.aws.amazon.com/vpc/home?#igws:
resource "aws_internet_gateway" "rhombus-igw" {
  vpc_id = aws_vpc.rhombus-vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# https://console.aws.amazon.com/vpc/home?#RouteTables:
resource "aws_route_table" "rhombus-tbl" {
  vpc_id = aws_vpc.rhombus-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.rhombus-igw.id
  }
  tags = {
    Name = "${var.cluster_name}-tbl"
  }
}

# https://console.aws.amazon.com/vpc/home?#NatGateways:
resource "aws_route_table_association" "rhombus-tbl-association" {
  count          = var.vpc-subnets
  subnet_id      = aws_subnet.rhombus-subnet[count.index].id
  route_table_id = aws_route_table.rhombus-tbl.id
}
