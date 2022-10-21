
module "sv01" {
  source = "../../vm"
  providers = {
    libvirt = libvirt.nuc1
  }
  prefix  = "amin0002" 
  id =      "01"
  bridge  = "br0" 
  ip4addr = "10.80.11.203"
  ip4gw   = "10.80.11.186"
  ip4dns  = "192.168.100.1" 
} 
module "sv02" {
  source = "../../vm"
  providers = {
    libvirt = libvirt.nuc1
  }
  prefix  = "amin0002" 
  id =      "02"
  bridge  = "br0" 
  ip4addr = "10.80.11.204"
  ip4gw   = "10.80.11.186"
  ip4dns  = "192.168.100.1" 
} 
module "sv03" {
  source = "../../vm"
  providers = {
    libvirt = libvirt.z51
  }
  prefix  = "amin0002" 
  id =      "03"
  bridge  = "br0" 
  ip4addr = "10.80.11.205"
  ip4gw   = "10.80.11.186"
  ip4dns  = "192.168.100.1" 
} 
