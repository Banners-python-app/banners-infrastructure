output "role_arn" {
    value = aws_iam_role.myrole.arn
    description = "ARN of created role"  
}

output "role_name" {
    value = aws_iam_role.myrole.name
    description = "Name of created role"
}

# If we are creating an EC2 instance, it needs an instance profile, not just a role.
# We output this so the EC2 module can use it.
resource "aws_iam_instance_profile" "this" {
    name = "${var.env}-${var.role_name}-profile"
    role = aws_iam_role.myrole.name
}

output "instance_prof_name" {
    value = aws_iam_instance_profile.this.name
    description = "The Name of the Instance Profile attached to this role"  
}