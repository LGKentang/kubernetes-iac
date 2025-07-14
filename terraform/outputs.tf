output "worker_ips" {
  value = {
    for k, v in local.workers : k => v.ip_address
  }
}

output "master_vm" {
  value = "master-1"
}
