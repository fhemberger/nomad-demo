require "ipaddr"

# Number of nodes to start. Vault and the controlpane (= Consul/Nomad server)
# should have three nodes for high availability, so the cluster can tolerate
# one failing node without losing quorum.
#
VAULT_NODES = 1
CONTROLPLANE_NODES = 3
WORKER_NODES = 1

# VirtualBox enforces host-only networks to be in the 192.168.56.0/21 IP range
# by default.
LOADBALANCER_IP = "192.168.56.20"
INTERNAL_NETWORK_RANGE = "192.168.56.128/25"

# Helper class: Give it a starting IP address and
# always get the next succeeding address
class IPList
  def initialize(ip)
    @current_ip = IPAddr.new(ip)
  end

  def next
    @current_ip = @current_ip.succ
    @current_ip.to_s
  end
end

$internal_network_ip = IPList.new(INTERNAL_NETWORK_RANGE)
$ansible_host_vars = {}

def configure_host(host, hostname)
  ipv4 = $internal_network_ip.next
  host.vm.network "private_network", ip: ipv4
  host.vm.hostname = hostname
  $ansible_host_vars.merge!(hostname => { "vagrant_ipv4": ipv4 })
end

# Getting the right IP address for a Vagrant-VM in Ansible is not easy:
#
# - `ansible_host` is not suitable in Vagrant (it's always "127.0.0.1")
#
# - The Ubuntu Vagrant box already comes with a preset interface `enp0s3`, so
#   `ansible_default_ipv4.address` has the same value ("10.0.2.15") __for all VMs__
#
# - Adding a new private network creates the interface `enp0s8`, but switching to
#   another Vagrant box (or even a different Ubuntu version) might change the
#   interface name. So reading a host var `ansible_enp0s8.ipv4.address`
#   is not ideal as well.
#
# But as I already define both hostname and IP address in Vagrant, I decided to
# add an additional host variable `vagrant_ipv4`for all my needs, falling back to
# `ansible_default_ipv4.address` in case the Ansible playbook is run without Vagrant.
#
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.define "tools" do |vagrant|
    configure_host vagrant, "tools"
  end

  # Vault nodes
  (1..VAULT_NODES).each do |node|
    config.vm.define "vault#{node}" do |vagrant|
      configure_host vagrant, "vault#{node}"
    end
  end

  # Consul/Nomad controlplane nodes
  (1..CONTROLPLANE_NODES).each do |node|
    config.vm.define "controlplane#{node}" do |vagrant|
      configure_host vagrant, "controlplane#{node}"
    end
  end

  # Nomad worker nodes
  (1..WORKER_NODES).each do |node|
    config.vm.define "worker#{node}" do |vagrant|
      configure_host vagrant, "worker#{node}"

      # Increase memory for Parallels Desktop
      vagrant.vm.provider "parallels" do |p, o|
        p.memory = "1024"
      end

      # Increase memory for Virtualbox
      vagrant.vm.provider "virtualbox" do |vb|
        vb.memory = "1024"
      end

      # Increase memory for VMware
      ["vmware_fusion", "vmware_workstation"].each do |p|
        vagrant.vm.provider p do |v|
          v.vmx["memsize"] = "1024"
        end
      end
    end
  end

  # Loadbalancer
  config.vm.define "loadbalancer" do |lb|
    lb.vm.network "private_network", ip: LOADBALANCER_IP
    lb.vm.hostname = "loadbalancer"
    $ansible_host_vars.merge!(lb.vm.hostname => { "vagrant_ipv4": LOADBALANCER_IP })
  end

  config.vm.provision "ansible", type: "ansible", run: "never" do |ansible|
    ansible.compatibility_mode = "2.0"
    ansible.limit = "all,localhost"
    ansible.playbook = "playbook.yml"
    ansible.host_vars = $ansible_host_vars
    ansible.groups = {
      "vault" => (1..VAULT_NODES).map { |node| "vault#{node}" },
      "controlplane" => (1..CONTROLPLANE_NODES).map { |node| "controlplane#{node}" },
      "worker" => (1..WORKER_NODES).map { |node| "worker#{node}" },
      "loadbalancer" => "loadbalancer",
      "all:vars" => {
        "vagrant_loadbalancer_ip" => LOADBALANCER_IP,
        "vagrant_internal_network_range" => INTERNAL_NETWORK_RANGE,
      },
    }
  end
end
