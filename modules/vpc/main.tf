# creating VPC
resource "aws_vpc" "ban_vcp" {
    # checkov:skip=CKV2_AWS_11: Not required for dev
    # checkov:skip=CKV2_AWS_12: Ensure the default security group of every VPC restricts all traffic
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
}

# fetching AZs
data "aws_availability_zones" "available" {
    state = "available"
}

# creating IGW GW
resource "aws_internet_gateway" "ban_igw" {
    vpc_id = aws_vpc.ban_vcp.id
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
}

# Creating public subnet
resource "aws_subnet" "ban_subnet_pub1" {
    vpc_id = aws_vpc.ban_vcp.id
    cidr_block = var.cidr_pub1
    availability_zone = data.aws_availability_zones.available.names[0]
    # checkov:skip=CKV_AWS_130: Intentianlly keep public for load balancers
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
        "kubernetes.io/role/elb" = "1"    # added for internet-facing LB's used by LBC
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
}

resource "aws_subnet" "ban_subnet_pub2" {
    vpc_id = aws_vpc.ban_vcp.id
    cidr_block = var.cidr_pub2
    availability_zone = data.aws_availability_zones.available.names[1]
    # checkov:skip=CKV_AWS_130: Intentianlly keep public for load balancers
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
        "kubernetes.io/role/elb" = "1"    # added for internet-facing LB's used by LBC
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
}

# route table creation
resource "aws_route_table" "vpc_public_route" {
    vpc_id = aws_vpc.ban_vcp.id
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
    depends_on = [ aws_vpc.ban_vcp ]
}

# route table gateway
resource "aws_route" "ban_toute" {
    route_table_id = aws_route_table.vpc_public_route.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ban_igw.id
    depends_on = [ aws_route_table.vpc_public_route, aws_internet_gateway.ban_igw ]
}

# route table association
resource "aws_route_table_association" "associate_pub1" {
    route_table_id = aws_route_table.vpc_public_route.id

    for_each = {
      "subnet1" = aws_subnet.ban_subnet_pub1.id
      "subnet2" = aws_subnet.ban_subnet_pub2.id 
    }
    subnet_id = each.value
    depends_on = [ aws_route.ban_toute ]
}

# elastic IP for NAT GW
resource "aws_eip" "ban_eip" {
    domain = "vpc"
    depends_on = [ aws_internet_gateway.ban_igw ]
    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }
}

# create NAT GW
resource "aws_nat_gateway" "ban_nat_gw" {
    allocation_id = aws_eip.ban_eip.id
    subnet_id = aws_subnet.ban_subnet_pub1.id
    depends_on = [ aws_eip.ban_eip, aws_subnet.ban_subnet_pub1, aws_subnet.ban_subnet_pub2 ]
}

# private subnet
resource "aws_subnet" "ban_subnet_pvt1" {
    vpc_id = aws_vpc.ban_vcp.id
    cidr_block = var.cidr_pvt1
    availability_zone = data.aws_availability_zones.available.names[1]
    tags = {
        Name                                     = "${var.vpc_name}-private-subnet-1"
        Environment                              = var.env
        Terraform                                = "true"
        "kubernetes.io/role/internal-elb"        = "1"     # added for internal LB's used by LBC
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "karpenter.sh/discovery" = var.cluster_name        # used by Karp for launching nodes
    }
}

resource "aws_subnet" "ban_subnet_pvt2" {
    vpc_id = aws_vpc.ban_vcp.id
    cidr_block = var.cidr_pvt2
    availability_zone = data.aws_availability_zones.available.names[2]
    tags = {
        Name                                     = "${var.vpc_name}-private-subnet-1"
        Environment                              = var.env
        Terraform                                = "true"
        "kubernetes.io/role/internal-elb"        = "1"     # added for internal LB's used by LBC
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "karpenter.sh/discovery" = var.cluster_name        # used by Karp for launching nodes
    }
}

# aws route table
resource "aws_route_table" "vpc_private_route" {
    vpc_id = aws_vpc.ban_vcp.id
    tags = {
        Name                                     = "${var.vpc_name}-private-subnet-1"
        Environment                              = var.env
        Terraform                                = "true"
    }
    depends_on = [ aws_vpc.ban_vcp ]
}

# aws route
resource "aws_route" "ban_route" {
    route_table_id = aws_route_table.vpc_private_route.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ban_nat_gw.id
    depends_on = [ aws_route_table.vpc_private_route, aws_nat_gateway.ban_nat_gw ]
}

# route table association
resource "aws_route_table_association" "associate_pvt" {
    route_table_id = aws_route_table.vpc_private_route.id
    for_each = {
      "subnet1" = aws_subnet.ban_subnet_pvt1.id,
      "subnet2" = aws_subnet.ban_subnet_pvt2.id 
    }
    subnet_id = each.value
    depends_on = [ aws_route.ban_route, aws_subnet.ban_subnet_pvt1, aws_subnet.ban_subnet_pvt2 ]
}

# NACl for public subnet
resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.ban_vcp.id
  # checkov:skip=CKV_AWS_231: Needed for pub nacls
  # checkov:skip=CKV_AWS_232: Needed for pub nacls
  for_each = {
    pub_subnet1 = aws_subnet.ban_subnet_pub1.id,
    pub_subnet2 = aws_subnet.ban_subnet_pub2.id
    }
  subnet_ids = [each.value]
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  ingress {
    protocol   = "udp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # ADD THIS: Allow ICMP (For Ping replies)
  ingress {
    protocol   = "icmp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    icmp_type  = -1 # Allows all ICMP types
    icmp_code  = -1 # Allows all ICMP codes
  }

  #allowing all traffic out
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}