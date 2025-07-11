# volumes.tf
resource "libvirt_volume" "ubuntu_base" {
  name = "focal-20.04-base.qcow2"
  pool = "default"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [source]
  }
}
