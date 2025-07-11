variable "vm_name" {
  description = "VM hostname"
  type        = string
  default     = "ubuntu-vm"
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "vcpu" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 16
}

variable "ubuntu_cloud_image_20_04" {
  default = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
}

