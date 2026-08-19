output "sg_public" {
    description = "For showing SG pub"
    value = aws_security_group.sg_public.id
}

output "sg_private" {
    description = "For SG pvt"
    value = aws_security_group.sg_private.id
}

output "sg_database" {
    description = "For SG dbs"
    value = aws_security_group.sg_database.id
}