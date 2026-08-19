# creating EC2 public instance
resource "aws_instance" "ec2_server" {
    ami = var.ami
    instance_type = var.instance_type
    subnet_id = var.subnet_id
    key_name = var.key_name
    vpc_security_group_ids = var.security_groups
    iam_instance_profile = var.iam_instance_profile
    user_data = var.user_data
    associate_public_ip_address = var.public_ip
    # checkov:skip=CKV_AWS_126: Ensure detailed monitoring is enabled
    #monitoring = true

    root_block_device {
      volume_size = var.volume_size
      encrypted = true
      volume_type = "gp3"
      delete_on_termination = true
    }

    # Checkov CKV_AWS_79: Require IMDSv2 for secure metadata access
    metadata_options {
      http_endpoint = "enabled"
      http_tokens = "required"
      http_put_response_hop_limit = 1
    }

    tags = {
        Name = "${var.vpc_name}-vpc",
        Environment = "${var.env}"
        Terraform = "true"
    }

}