resource "aws_lb" "service_alb" {
    load_balancer_type = "application"
    enable_cross_zone_load_balancing = true
    internal = false
    name            = "alb-${local.service_name}"
    subnets         = local.public_subnet_ids
    security_groups = [aws_security_group.security_group_80.id]
    depends_on = [
        aws_vpc.main
    ]
}

resource "aws_security_group" "security_group_80" {
    name        = "security-group-80-${local.service_name}"
    description = "HTTP 80 port open"
    vpc_id      = aws_vpc.main.id

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port        = 80
        to_port          = 80
        protocol         = "tcp"
        cidr_blocks      = concat([local.vpc_cidr_block], local.inbound_allow_ips)
    }
}

resource "aws_lb_listener" "service_lb_listener" {
    load_balancer_arn = aws_lb.service_alb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        type             = "fixed-response"
        fixed_response {
            status_code = 404
            content_type = "application/json"
            message_body = "{message: 'not found'}"
        }
    }

    lifecycle {
        ignore_changes = [
            default_action,
        ]
    }
}

resource "aws_lb_listener_rule" "service_lb_listener_rule" {
    listener_arn = aws_lb_listener.service_lb_listener.arn
    priority     = 100

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.service_target_group_a.id
    }

    condition {
        path_pattern { 
            values = ["/"]
        }
    }

    lifecycle {
        ignore_changes = [
            action
        ]
    }
}

resource "aws_lb_target_group" "service_target_group_a" {
    name        = "tg-${local.service_name}-a"
    port        = 3000
    protocol    = "HTTP"
    vpc_id      = aws_vpc.main.id
    target_type = "ip" // ip or lambda
    health_check {
        interval = 30
        path = "/"
        protocol = "HTTP"
        healthy_threshold = 3
        unhealthy_threshold = 2
    }
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_lb_target_group" "service_target_group_b" {
    name        = "tg-${local.service_name}-b"
    port        = 3000
    protocol    = "HTTP"
    vpc_id      = aws_vpc.main.id
    target_type = "ip" // ip or lambda
    health_check {
        interval = 30
        path = "/"
        protocol = "HTTP"
        healthy_threshold = 3
        unhealthy_threshold = 2
    }
    lifecycle {
        create_before_destroy = true
    }
}

output "service_lb_url" {
    value = aws_lb.service_alb.dns_name
}