terraform {
  required_providers {
    opennebula = {
      source  = "OpenNebula/opennebula"
      version = "1.2.2"
    }
  }
}

variable "one" {
  type = object({
    endpoint      = string
    flow_endpoint = string
    username      = string
    password      = string
  })
  default = {
    endpoint      = "http://10.11.12.13:2633/RPC2"
    flow_endpoint = "http://10.11.12.13:2474"
    username      = "oneadmin"
    password      = "asd123"
  }
}

data "http" "appliances" {
  url = "https://marketplace.opennebula.io/appliance"
  request_headers = {
    User-Agent = "OpenNebula 6.6.2"
    Accept     = "application/json"
  }
}

locals {
  appliances = {
    for a in jsondecode(data.http.appliances.response_body).appliances : a.name => a
  }

  name = "Service OneKE 1.27"

  service = local.appliances[local.name]

  roles = {
    for k, v in local.service.roles : k => merge(local.appliances[v], {
      opennebula_template = jsondecode(local.appliances[v].opennebula_template)
    })
  }

  md5_to_url = {
    for f in distinct(flatten([
      for r in values(local.roles) : concat(
        try(r.files, []),
        [for d in try(r.disks, []) : local.appliances[d].files]
      )
    ])) : f.md5 => f.url
  }

  role_to_md5 = {
    for k, v in local.roles : k => [
      for f in flatten(concat(
        try(v.files, []),
        [for d in try(v.disks, []) : local.appliances[d].files]
      )) : f.md5
    ]
  }
}

provider "opennebula" {
  endpoint      = var.one.endpoint
  flow_endpoint = var.one.flow_endpoint
  username      = var.one.username
  password      = var.one.password
}

resource "opennebula_image" "oneke" {
  for_each     = local.md5_to_url
  name         = "${local.name} ${each.key}"
  datastore_id = 1
  persistent   = false
  permissions  = 642
  dev_prefix   = "vd"
  driver       = "qcow2"
  path         = each.value
}

resource "opennebula_template" "oneke" {
  for_each = local.roles
  name     = "${local.name} ${each.key}"
  cpu      = try(each.value["opennebula_template"].CPU, null)
  vcpu     = try(each.value["opennebula_template"].VCPU, null)
  memory   = try(each.value["opennebula_template"].MEMORY, null)
  context  = try(each.value["opennebula_template"].CONTEXT, null)

  dynamic "graphics" {
    for_each = try([each.value["opennebula_template"].GRAPHICS], [])
    content {
      type   = try(graphics.value.TYPE, null)
      listen = try(graphics.value.LISTEN, null)
    }
  }

  dynamic "os" {
    for_each = try([each.value["opennebula_template"].OS], [])
    content {
      arch = try(os.value.ARCH, null)
      boot = "disk0"
    }
  }

  dynamic "disk" {
    for_each = local.role_to_md5[each.key]
    content {
      image_id = opennebula_image.oneke[disk.value].id
    }
  }
}

resource "opennebula_service_template" "oneke" {
  name        = local.name
  permissions = 642
  uname       = "oneadmin"
  gname       = "oneadmin"
  template = jsonencode({ "TEMPLATE" = { "BODY" = merge(
    jsondecode(local.service["opennebula_template"]),
    {
      "roles" : [
        for r in jsondecode(local.service["opennebula_template"]).roles : merge(
          r,
          { vm_template = tonumber(opennebula_template.oneke[r.name].id) }
        )
      ]
    }
  ) } })
}

resource "opennebula_service" "oneke" {
  name           = local.name
  template_id    = opennebula_service_template.oneke.id
  extra_template = jsonencode({
    networks_values = [
        { Public = { id = "0" } },
        { Private = { id = "1" } },
    ]
    custom_attrs_values = {
        ONEAPP_VROUTER_ETH0_VIP0        = "172.16.100.86"
        ONEAPP_VROUTER_ETH1_VIP0        = "172.20.100.86"
        ONEAPP_K8S_EXTRA_SANS           = "localhost,127.0.0.1"
        ONEAPP_K8S_LOADBALANCER_RANGE   = ""
        ONEAPP_K8S_LOADBALANCER_CONFIG  = ""
        ONEAPP_STORAGE_DEVICE           = "/dev/vdb"
        ONEAPP_STORAGE_FILESYSTEM       = "xfs"
        ONEAPP_VNF_NAT4_ENABLED         = "YES"
        ONEAPP_VNF_NAT4_INTERFACES_OUT  = "eth0"
        ONEAPP_VNF_ROUTER4_ENABLED      = "YES"
        ONEAPP_VNF_ROUTER4_INTERFACES   = "eth0,eth1"
        ONEAPP_VNF_HAPROXY_INTERFACES   = "eth0"
        ONEAPP_VNF_HAPROXY_REFRESH_RATE = "30"
        ONEAPP_VNF_HAPROXY_CONFIG       = ""
        ONEAPP_VNF_HAPROXY_LB2_PORT     = "443"
        ONEAPP_VNF_HAPROXY_LB3_PORT     = "80"
        ONEAPP_VNF_KEEPALIVED_VRID      = "1"
    }
  })
}
