# 目についた話題

## CRI(Container Rutime Interface)はDockerからContainerdへ

https://www.slideshare.net/KoheiTokunaga/dockercontainerd
kubernetesは、1.20からDocker非推奨、1.24からDockerサポート削除予定らしいよ。後継は下位のcontainerd

## Hasicorpが作ってるIaCのツールTerraformは、Cloudサービス/libvirtd上でVMの作成/削除ができる golang製

## kubesprayはAnsibleからkubeadmを打つもの

## HELMは事実上の標準ツールらしいよyaml形式のChartを食わせてdeployするらしい　golang製

# 詳細

## terraformとansibleの違い

- https://www.lac.co.jp/lacwatch/service/20201216_002380.html

## terraformインストール手順

- https://www.terraform.io/downloads

-  moduleの基本
- https://zenn.dev/sway/articles/terraform_biginner_modules
- module の分岐、filesetからのパラメータ読み込み
- https://tech.buty4649.net/entry/2022/07/22/191008
- terraform でcloudinitの書き方
- https://int128.hatenablog.com/entry/2020/06/01/173446

## terraform libvirt provider

- https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs
- https://github.com/dmacvicar/terraform-provider-libvirt

### libvirt自体のインストール手順

- https://www.server-world.info/query?os=Ubuntu_20.04&p=kvm&f=1

### openstackも使える

- 試していない
- https://qiita.com/nakkoh/items/503d5a442b33029baaeb



### terraform libvirtでvm作成

- terraform libvirtでvmを作る例
- https://ngyuki.hatenablog.com/entry/2020/08/11/220950
- https://github.com/dmacvicar/terraform-provider-libvirt/commit/22f096d9

- cloud-init用のイメージをlibvirt上におく

```
curl -O https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2111.qcow2c
virsh -c qemu+ssh://ubuntu@192.168.100.202/system vol-create-as --pool default --name CentOS-7-x86_64-GenericCloud-2111.qcow2c --capacity 0 --format qcow2
virsh -c qemu+ssh://ubuntu@192.168.100.202/system vol-upload --pool default --vol CentOS-7-x86_64-GenericCloud-2111.qcow2c --file ./CentOS-7-x86_64-GenericCloud-2111.qcow2c
```

- log確認

```
/var/lib/cloud/instance/user-data.txt
/var/log/cloud-init.log
/var/log/cloud-init-output.log
```

- terraform libvirtを使う上で、不具合があるworkaround

```
/etc/libvirt/qemu.conf
security_driver = "none"
```

## kubespray = ansibleでkubeadmを使う

試していない

- pyenvとかsystemのpythonを使うと、暗黙で環境がよごれるので
- anacondaとか
- pythonを1からbuildしてpath通すのがいいのではないか


## vmへのkubernetesインストール

kubesprayはkubeadmを使うので、まずはkubeadmで入れる


### swapがあるとkubeletが動かない

```
yum update
swapoff -a
/dev/mapper/centos-swap swap                    swap    defaults        0 0
```

### iptablesがバイバスされる問題対策 nftablesを使わない

centos8では回避方法がないのでkubeadmは使えないという表記があった

```
https://qiita.com/keomo/items/2c535b918f8aa4976e97
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

### SELINUX

```
# setenforce 0
# sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

### portをあける

```
# firewall-cmd --permanent --new-zone=k8s
# firewall-cmd --permanent --zone=k8s --add-port 6443/tcp
# firewall-cmd --permanent --zone=k8s --add-port 2379-2380/tcp
# firewall-cmd --permanent --zone=k8s --add-port 10250/tcp
# firewall-cmd --permanent --zone=k8s --add-port 10251/tcp
# firewall-cmd --permanent --zone=k8s --add-port 10252/tcp
# firewall-cmd --permanent --zone=k8s --add-port 30000-32767/tcp
# firewall-cmd --reload
```

## CRI（Container Runtime Interface）のインストール

Dockerはいらないcontainerdがいる
　　
### Docker install

- https://kubernetes.io/ja/docs/setup/production-environment/container-runtimes/

```
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo   https://download.docker.com/linux/centos/docker-ce.repo
sudo yum update -y && yum install -y \
  containerd.io \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin
sudo systemctl enable docker
sudo systemctl restart docker
docker ps
```


## kubernetes install

kubeadm, kubelet, kubectlを入れる

- repository

```
  cat > /etc/yum.repos.d/kube-rnetes.repo　<<EOF
  [kubernetes]
  name=Kubernetes
  baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
  enabled=1
  ##gpgcheck=1
  ##repo_gpgcheck=1
  gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
  EOF
```  

- install

```
  # yum install kubelet kubeadm --disableexcludes=kubernetes
  # systemctl enable kubelet && systemctl start kubelet
```

ここまではterraformに書いた

```
　　# kubeadm init  --pod-network-cidr=10.244.0.0/16 --kubernetes-version vX.XX.XX

　　# mkdir -p $HOME/.kube
　　# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
　　# chown $(id -u):$(id -g) $HOME/.kube/config

```

　　だめなときはreset

　　# kubeadm reset
　　# echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
　　# kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version v1.22.2
　　# mkdir -p $HOME/.kube
　　# sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
　　# sudo chown $(id -u):$(id -g) $HOME/.kube/config



- terraformではなくvagrantの例　やることをおおまかに掴みやすい？
- https://blog.framinal.life/entry/2020/04/12/131246


- CNI(calico,flannelなど)についておおまかな説明
- https://thinkit.co.jp/article/19007

