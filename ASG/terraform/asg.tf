
resource "random_id" "asg" {
  prefix      = "${var.env_name}-asg-"
  byte_length = 4
}

resource "aws_key_pair" "asg" {
  key_name   = random_id.asg.hex
  public_key = var.public_key
}

data "aws_ami" "asg" {
  most_recent = true

  filter {
    name   = "name"
    values = [ "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*" ]
  }

  filter {
    name   = "virtualization-type"
    values = [ "hvm" ]
  }

  owners = [ "099720109477" ]
}

resource "aws_launch_configuration" "asg-master" {
  name                        = "${random_id.asg.hex}-master"
  image_id                    = data.aws_ami.asg.image_id
  ebs_optimized               = false
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [ aws_security_group.sg-master.id ]
  key_name                    = aws_key_pair.asg.key_name

  root_block_device {
    volume_type           = "standard"
    volume_size           = 16
    delete_on_termination = true
    encrypted             = false
  }
}

resource "aws_launch_configuration" "asg-compute" {
  name                        = "${random_id.asg.hex}-compute"
  image_id                    = data.aws_ami.asg.image_id
  ebs_optimized               = false
  instance_type               = "t2.micro"
  associate_public_ip_address = false
  security_groups             = [ aws_security_group.sg-compute.id ]
  key_name                    = aws_key_pair.asg.key_name

  root_block_device {
    volume_type           = "standard"
    volume_size           = 16
    delete_on_termination = true
    encrypted             = false
  }
}

resource "aws_autoscaling_group" "asg-master" {
  name = "${random_id.asg.hex}-master"
  tag {
    key                 = "Name"
    value               = "${random_id.asg.hex}-master"
    propagate_at_launch = true
  }

  protect_from_scale_in = false

  min_size         = var.master_count
  max_size         = var.master_count
  desired_capacity = var.master_count
  force_delete     = true

  vpc_zone_identifier = [ aws_subnet.vpc-master.id ]

  launch_configuration = aws_launch_configuration.asg-master.name
}

resource "aws_autoscaling_group" "asg-compute" {
  name = "${random_id.asg.hex}-compute"
  tag {
    key                 = "Name"
    value               = "${random_id.asg.hex}-compute"
    propagate_at_launch = true
  }

  protect_from_scale_in = false

  min_size         = var.compute_count
  max_size         = var.compute_count
  desired_capacity = var.compute_count
  force_delete     = true

  vpc_zone_identifier = [ aws_subnet.vpc-compute.id ]

  launch_configuration = aws_launch_configuration.asg-compute.name
}

# vim:ts=2:sw=2:et:syn=terraform:
