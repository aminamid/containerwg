terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

variable "prefix" {}
variable "id" {}
variable "ip4addr" {}
variable "ip4gw" {}
variable "ip4dns" {}
variable "bridge" {}

resource libvirt_cloudinit_disk hoge {
  name = "cloudinit_${var.prefix}_${var.id}"
  pool = "default"

  user_data = <<-EOS

    #cloud-config
    timezone: Asia/Tokyo
    ssh_pwauth: true
    chpasswd:
      list: root:password
      expire: false
    users:
      - name: centos
        groups: wheel
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILdLtFdr/tuRzjzmVyL4NL38S9gUqCcz71JCMEmvV22t ubuntu@nuc1"
    write_files:
      - path: "/etc/yum.repos.d/kube-rnetes.repo"
        content: |
          [kubernetes]
          name=Kubernetes
          baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
          enabled=1
          ##gpgcheck=1
          ##repo_gpgcheck=1
          gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
    packages:
      - nc
      - lsof
      - sysstat
      - yum-utils
      - device-mapper-persistent-data
      - lvm2
    runcmd:
      - |
        setenforce 0
        sed -i -e 's/^\SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
        systemctl restart rsyslog
      - |
        cat >> /etc/sysctl.d/k8s.conf <<EOF
        net.bridge.bridge-nf-call-ip6tables = 1
        net.bridge.bridge-nf-call-iptables = 1
        EOF
      - |
        yum-config-manager --add-repo   https://download.docker.com/linux/centos/docker-ce.repo
        yum update -y
        yum install -y containerd.io docker-ce docker-ce-cli docker-compose-plugin
        systemctl enable docker
        systemctl restart docker
      - |
        yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
        systemctl enable kubelet
        systemctl start kubelet
  EOS

  network_config = <<-EOT
    version: 2
    ethernets:
      eth0:
        match:
          name: eth0
        dhcp4: false
        addresses:
          - ${var.ip4addr}
        gateway4: ${var.ip4gw}
        nameservers:
          addresses:
            - ${var.ip4dns}
  EOT
}

resource libvirt_volume hoge {
  name   = "${var.prefix}${var.id}.qcow2"
  pool   = "default"
  #source = "/home/ubuntu/tf-centos/CentOS-7-x86_64-GenericCloud-2111.qcow2c"
  #source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2111.qcow2c"
  base_volume_name = "CentOS-7-x86_64-GenericCloud-2111.qcow2c"
  base_volume_pool = "default"
}

#resource libvirt_network hoge {
#  name = "hoge"
#  mode = "bridge"
#  bridge = "br0"
#  autostart = "true"
#}

resource libvirt_domain hoge {
  name = "${var.prefix}${var.id}"

  memory = 3072
  vcpu = 2

  ## below "addresses" are identified by IP/MAC address table managed by the libvirt network
  ## So it is not available if dhcp server is out of libvirt
  #
  network_interface {
    bridge = "${var.bridge}"
  }
  #network_interface {
  #  network_name = "tfnet"
  #  addresses = ["10.80.11.203"]
  #  wait_for_lease = true
  #}
  #provisioner "local-exec" {
  #  command = "echo ${self.network_interface.0.addresses.0} >> hosts_centos7.txt"
  #}

  disk {
    volume_id = libvirt_volume.hoge.id
  }

  cloudinit = libvirt_cloudinit_disk.hoge.id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }


}

