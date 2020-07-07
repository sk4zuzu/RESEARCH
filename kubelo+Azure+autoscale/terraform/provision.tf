
data "external" "provision-masters" {
  program = [
    "python3", "${path.module}/external/instances.py",
  ]
  query = {
    rg_name   = azurerm_resource_group.rg.name
    vmss_name = azurerm_linux_virtual_machine_scale_set.vmss-master.name
  }
}

data "external" "provision-computes" {
  program = [
    "python3", "${path.module}/external/instances.py",
  ]
  query = {
    rg_name   = azurerm_resource_group.rg.name
    vmss_name = azurerm_linux_virtual_machine_scale_set.vmss-compute.name
  }
}

data "external" "provision-public" {
  program = [
    "python3", "${path.module}/external/public.py",
  ]
  query = {
    rg_name   = azurerm_resource_group.rg.name
    vmss_name = azurerm_linux_virtual_machine_scale_set.vmss-master.name
  }
}

resource "local_file" "provision-kubelo" {
  filename        = abspath("${path.module}/../../../../../LIVE/${var.env_name}/kubelo.ini")
  file_permission = "0644"

  content = templatefile("${path.module}/templates/kubelo.ini", {
    env_name      = var.env_name,
    public_ipv4   = jsondecode(data.external.provision-public.result.json)[0],
    master_hosts  = join("\n", jsondecode(data.external.provision-masters.result.json)),
    compute_hosts = join("\n", jsondecode(data.external.provision-computes.result.json)),
  })
}

resource "null_resource" "provision-kubelo" {
  depends_on = [ local_file.provision-kubelo ]

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
