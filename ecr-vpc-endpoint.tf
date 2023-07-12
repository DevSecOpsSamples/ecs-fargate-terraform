resource "aws_vpc_endpoint" "ecr" {
    vpc_id            = aws_vpc.main.id
    service_name = "com.amazonaws.${local.region}.ecr.dkr"
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true
    security_group_ids = [aws_security_group.ecr_endpoint_sg.id]
    subnet_ids = local.private_subnet_ids
}

resource "aws_security_group" "ecr_endpoint_sg" {
    name        = "${local.service_name}-ecr-sg"
    description = "ECR VPC Enpoint SG"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = "80"
        to_port     = "80"
        protocol    = "TCP"
        cidr_blocks = [local.vpc_cidr_block]
    }

    ingress {
        from_port   = "443"
        to_port     = "443"
        protocol    = "TCP"
        cidr_blocks = [local.vpc_cidr_block]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}