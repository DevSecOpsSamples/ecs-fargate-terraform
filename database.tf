resource "aws_rds_cluster" "aurora_cluster_database" {
    cluster_identifier      = "aurora-${local.service_name}"
    engine                  = "aurora-mysql"
    engine_version          = "8.0.mysql_aurora.3.02.0"
    availability_zones      = [data.aws_availability_zones.available.names[0], 
                                data.aws_availability_zones.available.names[1]]
    database_name           = "exampleapp"
    master_username         = "admin"
    master_password         = "qwer1234!!"
    backup_retention_period = 5
    preferred_backup_window = "02:00-04:00"
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
    vpc_security_group_ids = [
        aws_security_group.security_group_mysql.id,
    ]
    lifecycle {
        ignore_changes = [
            availability_zones,
            engine_version
        ]
    }

    depends_on = [ aws_vpc.main ]
}

resource "aws_rds_cluster_instance" "aurora_cluster_instances" {
    count              = 2
    identifier         = "aurora-${local.service_name}-c${count.index}"
    cluster_identifier = aws_rds_cluster.aurora_cluster_database.id
    instance_class     = local.rdb_instance_class
    engine             = aws_rds_cluster.aurora_cluster_database.engine
    engine_version     = aws_rds_cluster.aurora_cluster_database.engine_version
    publicly_accessible = true
    db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group.name
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
    name          = "subnet-group-${local.service_name}"
    description   = "Allowed subnets for Aurora DB cluster instances"
    subnet_ids    = local.database_subnet_ids
}


resource "aws_security_group" "security_group_mysql" {
    name        = "mysql-sg-${local.service_name}"
    description = "HTTP 3306 port open interally"
    vpc_id      = aws_vpc.main.id

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {    
        from_port         = 3306
        to_port           = 3306
        protocol          = "tcp"
        cidr_blocks = concat([local.vpc_cidr_block], local.inbound_allow_ips)
    }
}