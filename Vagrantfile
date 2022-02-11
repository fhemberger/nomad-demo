def get_ip(index = 1)
  $ip_range.sub('xx', (index).to_s)
end

CONSUL_NOMAD_NODES = 3

# VirtualBox enforces host-only networks to be in the 192.168.56.0/21 IP range
# by default.
$ip_range = '192.168.56.2xx'
$all_nodes = Array.new(CONSUL_NOMAD_NODES).fill { |i| "#{get_ip(i + 1)}" }

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/focal64"

  (1..CONSUL_NOMAD_NODES).each do |i|
    config.vm.define "consul-nomad-node#{i}" do |node|
      node_ip_address = "#{get_ip(i)}"
      node.vm.network "private_network", ip: node_ip_address
      node.vm.hostname = "consul-nomad-node#{i}"

      # Increase memory for Virtualbox
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "1024"
      end
    end
  end

  config.vm.define "loadbalancer" do |lb|
    node_ip_address = "#{get_ip(0)}"
    lb.vm.network "private_network", ip: node_ip_address
    lb.vm.hostname = "loadbalancer"
  end

  config.vm.provision "ansible", type: "ansible", run: "never" do |ansible|
    ansible.compatibility_mode = "2.0"
    ansible.limit = "all,localhost"
    ansible.playbook = "playbook.yml"
    ansible.groups = {
      "consul_nomad" => (1..CONSUL_NOMAD_NODES).map { |node| "consul-nomad-node#{node}" },
      "all:vars" => {
        "vagrant_consul_nomad_ips" => $all_nodes,
        "vagrant_loadbalancer_ip" => "#{get_ip(0)}"
      }
    }
  end
end
