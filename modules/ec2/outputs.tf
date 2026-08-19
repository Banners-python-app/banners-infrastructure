output "instance_id" {
    description = "Inst ID"
    value = aws_instance.ec2_server.id
}

output "public_ip" {
    description = "EC2 pub IP"
    value = aws_instance.ec2_server.public_ip
}

output "private_ip" {
    description = "Pvt IP"
    value = aws_instance.ec2_server.private_ip
}

output "instance_arn" {
    description = "Inst ARN"
    value = aws_instance.ec2_server.arn
}