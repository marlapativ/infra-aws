resource "aws_vpc" "cluster" {
  cidr_block = var.vpc_cidr_range

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.cluster.id
  cidr_block        = var.private_subnets[count.index].cidr_range
  availability_zone = var.private_subnets[count.index].zone

  tags = {
    Name = var.private_subnets[count.index].name
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.cluster.id
  cidr_block        = var.public_subnets[count.index].cidr_range
  availability_zone = var.public_subnets[count.index].zone

  tags = {
    Name = var.public_subnets[count.index].name
  }
}

resource "aws_internet_gateway" "cluster" {
  vpc_id = aws_vpc.cluster.id

  tags = {
    Name = var.internet_gateway_name
  }
}

resource "aws_default_route_table" "cluster" {
  default_route_table_id = aws_vpc.cluster.default_route_table_id

  route {
    cidr_block = var.route_cidr
    gateway_id = aws_internet_gateway.cluster.id
  }

  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route_table_association" "public_routes" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_default_route_table.cluster.id
}

resource "aws_default_network_acl" "cluster" {
  default_network_acl_id = aws_vpc.cluster.default_network_acl_id
  subnet_ids             = [aws_subnet.cluster.id]

  dynamic "ingress" {
    for_each = var.network_acl_ingress
    content {
      protocol   = ingress.value.protocol
      rule_no    = ingress.value.number
      action     = ingress.value.action
      cidr_block = ingress.value.cidr
      from_port  = ingress.value.port
      to_port    = ingress.value.port
    }
  }

  dynamic "egress" {
    for_each = var.network_acl_egress
    content {
      protocol   = egress.value.protocol
      rule_no    = egress.value.number
      action     = egress.value.action
      cidr_block = egress.value.cidr
      from_port  = egress.value.port
      to_port    = egress.value.port
    }
  }
}
