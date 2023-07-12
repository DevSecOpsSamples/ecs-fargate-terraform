locals {
    region = "ap-northeast-2"
    ip_range = "10.100"
    service_name = "ecs-fargate-terraform"
    elasticache_node_type = "cache.t4g.micro"
    rdb_instance_class = "db.r6g.large"
    private_subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]
    public_subnet_ids = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]
    elasticache_subnet_ids = [aws_subnet.elasticache_subnet[0].id, aws_subnet.elasticache_subnet[1].id]
    database_subnet_ids = [aws_subnet.database_subnet[0].id, aws_subnet.database_subnet[1].id]
    vpc_cidr_block = aws_vpc.main.cidr_block
    tag_name = local.service_name
    example_app_name = "nodejs-sample"
    inbound_allow_ips = [ 
        "111.111.111.111/32",     // eg. office1
        "222.222.222.222/32",     // eg. office1
    ]
}