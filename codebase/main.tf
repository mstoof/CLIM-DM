provider "aws" {
  region = "eu-paris-3"
}

resource "aws_launch_configuration" "Clim-DM" {
  image_id        = "<AMI-ID>"
  instance_type  = "t3.micro"
  security_groups = [aws_security_group.Clim-DM.id]
  user_data       = data.template_file.user_data.rendered
}

resource "aws_security_group" "Clim-DM" {
  name_prefix = "Clim-DM"
}

resource "aws_autoscaling_group" "Clim-DM" {
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.Clim-DM.id
  max_size             = 5
  min_size             = 1
  name                 = "Clim-DM-asg"
  target_group_arns    = [aws_lb_target_group.Clim-DM.arn]
  vpc_zone_identifier  = [aws_subnet.public.*.id]
}

data "template_file" "user_data" {
  template = file("userdata.sh")
}

resource "aws_lb" "Clim-DM" {
  internal = false
  load_balancer_type = "application"
  name               = "Clim-DM-lb"
  security_groups    = [aws_security_group.Clim-DM.id]
  subnets            = [aws_subnet.public.*.id]
}

resource "aws_lb_target_group" "Clim-DM" {
  name     = "Clim-DM-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id
}

resource "aws_lb_listener" "Clim-DM" {
  load_balancer_arn = aws_lb.Clim-DM.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.Clim-DM.arn
    type             = "forward"
  }
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  vpc_id            = aws_vpc.default.id
}

