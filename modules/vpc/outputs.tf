output "ban_subnet_pub1" {
    description = "Pub submet 1"
    value = aws_subnet.ban_subnet_pub1.id
}

output "ban_subnet_pub2" {
    description = "Pub subnet 2"
    value = aws_subnet.ban_subnet_pub2.id
}

output "ban_eip" {
    description = "EIP"
    value = aws_eip.ban_eip.public_ip
}

output "ban_subnet_pvt1" {
    description = "Pvt subnet 1"
    value = aws_subnet.ban_subnet_pvt1.id
}

output "ban_subnet_pvt2" {
    description = "Pvt subnet 2"
    value = aws_subnet.ban_subnet_pvt2.id
}

output "vpc_cidr" {
    description = "VPC CIDR"
    value = aws_vpc.ban_vcp.cidr_block
}

output "vpc_id" {
    description = "VPC id"
    value = aws_vpc.ban_vcp.id
}