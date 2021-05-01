$vault_nodes = 1
$controlplane_nodes = 3
$worker_nodes = 1
$loadbalancer_ip = "10.1.10.20"

$ansible_groups = {
  "vault" => (1..$vault_nodes).map { |node| "vault#{node}" },
  "controlplane" => (1..$controlplane_nodes).map { |node| "controlplane#{node}" },
  "worker" => (1..$worker_nodes).map { |node| "worker#{node}" },
  "all:vars" => {
    "vagrant_loadbalancer_ip" => $loadbalancer_ip,
  },
}

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.network "private_network", type: "dhcp"

  # Vault nodes
  (1..$vault_nodes).each do |node|
    config.vm.define "vault#{node}" do |vault|
      vault.vm.hostname = "vault#{node}"

      if node == $vault_nodes
        vault.vm.provision "ansible" do |ansible|
          ansible.playbook = "deploy-vault.yml"
          ansible.groups = $ansible_groups
          ansible.limit = "vault"
        end
      end
    end
  end

  # Consul/Nomad controlplane nodes
  (1..$controlplane_nodes).each do |node|
    config.vm.define "controlplane#{node}" do |controlplane|
      controlplane.vm.hostname = "controlplane#{node}"

      if node == $controlplane_nodes
        controlplane.vm.provision "ansible" do |ansible|
          ansible.playbook = "deploy-controlplane.yml"
          ansible.groups = $ansible_groups
          ansible.limit = "controlplane"
        end
      end
    end
  end

  # Nomad worker nodes
  (1..$worker_nodes).each do |node|
    config.vm.define "worker#{node}" do |worker|
      worker.vm.hostname = "worker#{node}"

      # Increase memory for Parallels Desktop
      worker.vm.provider "parallels" do |p, o|
        p.memory = "1024"
      end

      # Increase memory for Virtualbox
      worker.vm.provider "virtualbox" do |vb|
        vb.memory = "1024"
      end

      # Increase memory for VMware
      ["vmware_fusion", "vmware_workstation"].each do |p|
        worker.vm.provider p do |v|
          v.vmx["memsize"] = "1024"
        end
      end

      if node == $worker_nodes
        worker.vm.provision "ansible" do |ansible|
          ansible.playbook = "deploy-nomad-worker.yml"
          ansible.groups = $ansible_groups
        end
      end
    end
  end

  # Loadbalancer and DNS
  config.vm.define "loadbalancer" do |lb|
    lb.vm.network "private_network", ip: $loadbalancer_ip
    lb.vm.hostname = "loadbalancer"
    lb.vm.provision "ansible" do |ansible|
      ansible.playbook = "deploy-loadbalancer.yml"
      ansible.groups = $ansible_groups
    end
  end
end
