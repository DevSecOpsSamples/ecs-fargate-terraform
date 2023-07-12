data "aws_caller_identity" "current" {}

resource "aws_ecs_cluster" "ecs_cluster" {
    name = "ecs-${local.service_name}"
}

resource "aws_ecs_cluster_capacity_providers" "fargate_spot_provider" {
    cluster_name = aws_ecs_cluster.ecs_cluster.name

    capacity_providers = ["FARGATE_SPOT"]

    default_capacity_provider_strategy {
        base              = 1
        weight            = 100
        capacity_provider = "FARGATE_SPOT"
    }
}

resource "aws_cloudwatch_log_group" "app_log_group" {
    name = "${local.service_name}-app-log-group"
    retention_in_days = 14
}

resource "aws_security_group" "security_group_exampleapp" {
    name        = "security-group-3000-${local.service_name}"
    description = "HTTP 3000 port open internally"
    vpc_id      = aws_vpc.main.id

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port        = 3000
        to_port          = 3000
        protocol         = "tcp"
        cidr_blocks      = [
            "${local.vpc_cidr_block}",    // vpc
        ]
    }
}

resource "aws_ecs_service" "service" {
    name = "ecs-service-${local.service_name}"
    cluster = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.default_task_definition.id
    desired_count = 2
    launch_type = "FARGATE"

    deployment_controller {
        type = "CODE_DEPLOY"
    }

    network_configuration {
        security_groups = [aws_security_group.security_group_exampleapp.id]
        subnets = local.private_subnet_ids
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.service_target_group_a.arn
        container_name = "${local.example_app_name}-app"
        container_port = 3000
    }

    lifecycle {
        ignore_changes = [
          task_definition,
          load_balancer
        ]
    }
}

##
## executed only once, when initializing infrastructure
##
resource "aws_ecs_task_definition" "default_task_definition" {
    family                   = "${local.example_app_name}-app"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu                      = 1024
    memory                   = 2048
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_role.arn
    container_definitions = <<DEFINITION
    [
        {
            "image": "registry.gitlab.com/architect-io/artifacts/nodejs-hello-world:latest",
            "cpu": 1024,
            "memory": 2048,
            "name": "${local.example_app_name}-app",
            "networkMode": "awsvpc",
            "portMappings": [
                {
                    "containerPort": 3000,
                    "hostPort": 3000
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "${local.service_name}-app-log-group",  
                    "awslogs-region": "${local.region}",
                    "awslogs-stream-prefix": "${local.example_app_name}"
                }
            }
        }
    ]
    DEFINITION
}


