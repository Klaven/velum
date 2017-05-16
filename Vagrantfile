# -*- mode: ruby -*-
# vi: set ft=ruby :

def provision_script
  <<SCRIPT
  sudo apt-get update -y
  sudo apt-get install -y curl linux-image-extra-$(uname -r) linux-image-extra-virtual
  sudo apt-get install -y apt-transport-https software-properties-common ca-certificates
  curl -fsSL https://yum.dockerproject.org/gpg | sudo apt-key add -
  echo "deb https://apt.dockerproject.org/repo/ ubuntu-$(lsb_release -cs) main" > /etc/apt/sources.list.d/99-docker.list
  sudo apt-get update -y
  sudo apt-get -y install docker-engine
  [ -f kubernetes.tar.gz ] || curl -LO https://github.com/kubernetes/kubernetes/releases/download/v1.5.2/kubernetes.tar.gz
  [ -d kubernetes ] || tar -xvzf kubernetes.tar.gz
  [ -d kubernetes/client/bin ] || /home/vagrant/kubernetes/cluster/get-kube-binaries.sh
  [ -d kubernetes/server/kubernetes ] || (cd kubernetes/server && tar -xvzf kubernetes-server-linux-amd64.tar.gz)
  grep kubernetes/client .bashrc || echo "PATH=/home/vagrant/kubernetes/client/bin:\\$PATH" >> .bashrc
  grep kubernetes/server .bashrc || echo "PATH=/home/vagrant/kubernetes/server/kubernetes/server/bin:\\$PATH" >> .bashrc
  find kubernetes/client/bin -type f | xargs -I cp {} /usr/bin/
  find kubernetes/server/kubernetes/server/bin -type f | xargs -I{} cp {} /usr/bin/
  sudo usermod -aG docker,root vagrant
  sudo chown -R vagrant:vagrant .
SCRIPT
end

Vagrant.configure("2") do |config|
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  # Forward Salt Master ports so that Terraform
  # deployed Salt Minions can talk to this VM
  config.vm.network "forwarded_port", guest: 4505, host: 4505
  config.vm.network "forwarded_port", guest: 4506, host: 4506

  config.vm.provision "shell", inline: provision_script
  config.vm.synced_folder ".", "/vagrant"
  config.vm.box = "boxcutter/ubuntu1610"

  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 2
  end

  config.vm.provider "libvirt" do |v, override|
    override.vm.box = "yk0/ubuntu-xenial"
    v.memory = 4096
    v.cpus = 2
  end
end
