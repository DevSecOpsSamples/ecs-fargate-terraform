resource "aws_elasticache_cluster" "redis" {
    cluster_id           = "elasticache-${local.service_name}"
    engine               = "redis"
    node_type            = local.elasticache_node_type
    num_cache_nodes      = 1
    parameter_group_name = "default.redis7"
    engine_version       = "7.0"
    port                 = 6379
    subnet_group_name    = aws_elasticache_subnet_group.cache.name
    security_group_ids   = [aws_security_group.elasticache_sg.id]
}

resource "aws_elasticache_subnet_group" "cache" {
    name       = "elasticache-subnet-${local.service_name}"
    subnet_ids = local.elasticache_subnet_ids
}


resource "aws_security_group" "elasticache_sg" {
    name        = "${local.service_name}-cache-sg"
    description = "Elasticache SG"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = "6379"
        to_port     = "6379"
        protocol    = "TCP"
        cidr_blocks = concat([local.vpc_cidr_block], local.inbound_allow_ips)
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output elasticache_url {
    value = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.cache_nodes[0].port}"
}