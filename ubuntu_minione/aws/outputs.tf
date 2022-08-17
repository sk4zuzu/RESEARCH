output "public_ipv4" {
  value = try(aws_instance.self[0].public_ip, "")
}

output "public_ssh" {
  value = "ssh ubuntu@${try(aws_instance.self[0].public_ip,"")}"
}
