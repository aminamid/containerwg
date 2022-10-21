terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider libvirt {
  alias = "nuc1"
  #uri = "qemu+ssh://root@192.168.100.202/system?keyfile=/home/ubuntu/.ssh/id_ed25519&sshauth=privkey&no_verify=1&no_tty=1"
  uri = "qemu+ssh://ubuntu@10.80.11.202/system?keyfile=/home/ubuntu/.ssh/id_ed25519&sshauth=privkey&no_verify=1&no_tty=1"
}

provider libvirt {
  alias = "z51"
  uri = "qemu+ssh://ubuntu@10.80.11.188/system?keyfile=/home/ubuntu/.ssh/id_ed25519&sshauth=privkey&no_verify=1&no_tty=1"
}
