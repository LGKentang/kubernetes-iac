resource "libvirt_network" "bridged_network" {
  name   = "k8s-bridge"
  mode   = "bridge"
  bridge = "br0"
}

# master-1 configurations
resource "libvirt_volume" "ubuntu_disk_master" {
  name           = "master-1.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base.id
  format         = "qcow2"
  size           = 10000000000

}

resource "libvirt_cloudinit_disk" "cloudinit_master" {
  name           = "cloudinit-master.iso"
  pool           = "default"
  user_data      = file("${path.module}/cloud-init/01-master-cloudinit.cfg")
  network_config = file("${path.module}/network-config/01-network-config.yaml")
}


resource "libvirt_domain" "vm_master" {
  name   = "master-1"
  memory = var.memory
  vcpu   = var.vcpu

  disk {
    volume_id = libvirt_volume.ubuntu_disk_master.id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit_master.id

  network_interface {
    network_id = libvirt_network.bridged_network.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}

locals {
  workers = {
    "worker-1" = {
      cloudinit_cfg = "02-worker-cloudinit.cfg"
      network_cfg   = "02-network-config.yaml"
      hostname      = "KUBE-WORKER-TERRAFORM-1"
      vm_name      = "worker-1"
      ip_address    = "192.168.1.16"
    },
    "worker-2" = {
      cloudinit_cfg = "03-worker-cloudinit.cfg"
      network_cfg   = "03-network-config.yaml"
      hostname      = "KUBE-WORKER-TERRAFORM-2"
      vm_name      = "worker-2"
      ip_address    = "192.168.1.17"
    }
  }
}

# workers
resource "libvirt_volume" "ubuntu_disk_worker" {
  for_each = local.workers

  name           = "${each.key}.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu_base.id
  format         = "qcow2"
  size           = 10000000000

}

data "template_file" "worker_user_data" {
  for_each = local.workers
  template = file("${path.module}/cloud-init/cloud-init.tmpl")

  vars = {
    hostname   = each.value.hostname
    vm_name    = each.value.vm_name
    ip_address = each.value.ip_address
  }
}

resource "libvirt_cloudinit_disk" "cloudinit_worker" {
  for_each = local.workers

  name           = "cloudinit-${each.key}.iso"
  pool           = "default"
  user_data      = data.template_file.worker_user_data[each.key].rendered
  network_config = file("${path.module}/network-config/${each.value.network_cfg}")
}

resource "libvirt_domain" "vm_worker" {
  for_each = local.workers

  name   = each.key
  memory = var.memory
  vcpu   = var.vcpu

  disk {
    volume_id = libvirt_volume.ubuntu_disk_worker[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit_worker[each.key].id

  network_interface {
    network_id = libvirt_network.bridged_network.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  graphics {
    type        = "vnc"
    listen_type = "address"
    autoport    = true
  }
}

