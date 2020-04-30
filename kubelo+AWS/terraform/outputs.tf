
output "public_ipv4" {
  value = jsondecode(data.external.provision-public.result.json)[0]
}

output "ssh_command" {
  value = "ssh -o ForwardAgent=yes ubuntu@${jsondecode(data.external.provision-public.result.json)[0]} -t sudo -i"
}

# vim:ts=2:sw=2:et:syn=terraform:
