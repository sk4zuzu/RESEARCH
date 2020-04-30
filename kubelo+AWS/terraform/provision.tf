
data "external" "provision-master" {
  program = [
    "python3", "${path.module}/external/instances.py",
  ]
  query = {
    vpc_id = aws_vpc.vpc.id
    asg_id = aws_autoscaling_group.asg-master.id
  }
}

data "external" "provision-compute" {
  program = [
    "python3", "${path.module}/external/instances.py",
  ]
  query = {
    vpc_id = aws_vpc.vpc.id
    asg_id = aws_autoscaling_group.asg-compute.id
  }
}

data "external" "provision-public" {
  program = [
    "python3", "${path.module}/external/public.py",
  ]
  query = {
    vpc_id = aws_vpc.vpc.id
    asg_id = aws_autoscaling_group.asg-master.id
  }
}

resource "local_file" "provision-kubelo" {
  filename        = abspath("${path.module}/../../../../../LIVE/${var.env_name}/kubelo.ini")
  file_permission = "0644"

  content = templatefile("${path.module}/templates/kubelo.ini", {
    env_name      = var.env_name,
    public_ipv4   = jsondecode(data.external.provision-public.result.json)[0],
    master_hosts  = join("\n", jsondecode(data.external.provision-master.result.json)),
    compute_hosts = join("\n", jsondecode(data.external.provision-compute.result.json)),
  })
}

resource "null_resource" "provision-kubelo" {
  depends_on = [
    local_file.provision-kubelo,
    aws_autoscaling_group.asg-master,
    aws_autoscaling_group.asg-compute,
    aws_route_table_association.vpc-private,
  ]

  triggers = {
    always = uuid()
  }

  provisioner "local-exec" {
    command = <<-EOF
    set -o errexit
    cd $PLAYBOOK_DIR/ && make kubelo metrics
    EOF
    environment = {
      PLAYBOOK_DIR = abspath("${path.module}/../../../../../kubelo/")
      INVENTORY    = abspath("${path.module}/../../../../../LIVE/${var.env_name}/kubelo.ini")
    }
  }
}

# vim:ts=2:sw=2:et:syn=terraform:
