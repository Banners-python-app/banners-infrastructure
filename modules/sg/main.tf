#security groups for public subnet
resource "aws_security_group" "sg_public" {
  # checkov:skip=CKV2_AWS_5: OK
  vpc_id      = var.ban_vpcid
  name        = "${var.vpc_name}-pub-sg"
  description = "Allow required rules"
  tags = {
    Name        = "${var.vpc_name}-pub-sg"
    Environment = var.env
    Terraform   = "true"
  }

  ingress {
    # checkov:skip=CKV_AWS_260: Egress required
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  ingress {
    # checkov:skip=CKV_AWS_24: Egress required
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  egress {
    # checkov:skip=CKV_AWS_382: Egress required 
    protocol    = "-1"    # all protocols
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

#sg for pvt subnet
resource "aws_security_group" "sg_private" {
  # checkov:skip=CKV2_AWS_5: OK
  vpc_id      = var.ban_vpcid
  name        = "${var.vpc_name}-sg-private"
  description = "SG for pvt subnets"
  tags = {
    Name        = "${var.vpc_name}-pvt-sg"
    Environment = var.env
    Terraform   = "true"
    "karpenter.sh/discovery" = var.cluster_name     # used by Karp for attaching this SGs to nodes
    # shared: this resource is used by other resources also like EKS/EC2 so dont delete or modify it if u have permissions to it
    # owned: this resource is only used by this cluster so if deleted then you can delete or modify it
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  ingress {
    description     = "Allow traffic from public SG"
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    security_groups = [aws_security_group.sg_public.id] #allowing only if it come from sg public
  }

  # CRITICAL: Allows the EKS control plane and worker nodes to talk to each other
  ingress {
    # checkov:skip=CKV_AWS_382
    description = "Allow internal cluster and node communication"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [ var.vpc_cidr_block ]
  }

  egress {
    # checkov:skip=CKV_AWS_382: Required
    description = "Allow all outbound traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#sg for db
# checkov:skip=CKV2_AWS_5
resource "aws_security_group" "sg_database" {
  # checkov:skip=CKV2_AWS_5: OK
  vpc_id      = var.ban_vpcid
  name        = "${var.vpc_name}-sg-database"
  description = "SG for DB"
  tags = {
    Name        = "${var.vpc_name}-pvt-sg"
    Environment = var.env
    Terraform   = "true"
  }

  ingress {
    description     = "Allow PostgreSQL traffic from private SG"
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.sg_private.id] #allowing only if it come from sg pvt subnet
  }

  egress {
    description = "Allow internal VPC traffic out"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr_block] # Only allow talk inside our VPC
  }

}