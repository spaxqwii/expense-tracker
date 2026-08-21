provider "aws" {
  region = "eu-west-1"
}

resource "aws_ecs_cluster" "main" {
  name = "expense-tracker-cluster"
}

data "aws_caller_identity" "current" {}

locals {
  ecr_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.eu-west-1.amazonaws.com/expense-tracker:latest"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "expense-tracker"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "256"
  memory                   = "256"

  container_definitions = jsonencode([
    {
      name   = "expense-tracker"
      image  = local.ecr_image
      cpu    = 256
      memory = 256
      environment = [
        { name = "AWS_ACCESS_KEY_ID", value = var.container_access_key_id },
        { name = "AWS_SECRET_ACCESS_KEY", value = var.container_secret_access_key },
        { name = "AWS_DEFAULT_REGION", value = "eu-west-1" }
      ]
      essential = true
      portMappings = [
        { containerPort = 8000, hostPort = 8000 }
      ]
    }
  ])
}

# IAM role that lets the EC2 instance join the ECS cluster
resource "aws_iam_role" "ecs_instance_role" {
  name = "expense-tracker-ecs-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "expense-tracker-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_iam_role" "ecs_task_role" {
  name = "expense-tracker-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_key_pair" "deployer" {
  key_name   = "expense-tracker-key"
  public_key = file("~/.ssh/expense_tracker_ec2.pub")
}

resource "aws_iam_role_policy" "ecs_task_dynamodb" {
  name = "expense-tracker-dynamodb-access"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:Scan"]
      Resource = "arn:aws:dynamodb:eu-west-1:${data.aws_caller_identity.current.account_id}:table/expenses"
    }]
  })
}

# Security group: allow the app port in, everything out
resource "aws_security_group" "ecs_instance_sg" {
  name        = "expense-tracker-ecs-sg"
  description = "Allow inbound app traffic for expense tracker"

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # fine for a personal debugging instance; tighten to your own IP if you want
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The ECS-optimized AMI, looked up automatically (avoids hardcoding an AMI ID that changes over time)
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_instance" "ecs_instance" {
  ami                         = data.aws_ssm_parameter.ecs_ami.value
  instance_type               = "t3.micro" # free tier eligible
  iam_instance_profile        = aws_iam_instance_profile.ecs_instance_profile.name
  vpc_security_group_ids      = [aws_security_group.ecs_instance_sg.id]
  key_name                    = aws_key_pair.deployer.key_name # ← add this
  user_data_replace_on_change = true                           # ← add this

  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
              echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
              EOF

  tags = {
    Name = "expense-tracker-ecs-instance"
  }
}

#The ECS Service (ties task definition + cluster together)
resource "aws_ecs_service" "app" {
  name            = "expense-tracker-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "EC2"
}