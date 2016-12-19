
Vagrant.configure("2") do |config|

#  config.ssh.private_key_path='/home/jdowling/.vagrant.d/insecure_private_key'
#  config.ssh.private_key_path='/home/jdowling/.ssh/id_rsa'
   config.ssh.insert_key = false
 
  config.vm.define "web01", primary: true do |web01|
BOX               = 'opscode-ubuntu-14.04'
BOX_URL           = 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box'

    web01.vm.box = "opscode-ubuntu-14.04"
    web01.vm.hostname = 'web01'
    web01.vm.box_url = 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box'

    web01.vm.network :private_network, ip: "192.168.56.101"
    web01.vm.network :forwarded_port, guest: 22, host: 10122, id: "ssh"
    web01.vm.network(:forwarded_port, {:guest=>9090, :host=>8181})     


    web01.vm.provision "file", source: "cluster.yml", destination: "cluster.yml"
    web01.vm.provision "file", source: "~/.vagrant.d/insecure_private_key", destination: "~/.ssh/id_rsa"    
    web01.vm.provision "shell", inline: "cp ~/.ssh/authorized_keys ~/.ssh/id_rsa.pub"
    
    web01.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 512]
      v.customize ["modifyvm", :id, "--name", "web01"]      
    end

    web01.vm.provision :chef_solo do |chef|
        chef.cookbooks_path = "cookbooks"
        chef.json = {
          "karamel" => {
	    "default" =>      { 
   	      "private_ips" => ["10.0.2.15"]
	    },
          },
        }

        chef.add_recipe "karamel::install"
#        chef.add_recipe "karamel::default"     
      end
    
  end

  #  config.vm.define "web02", autostart: false do |web02|
  config.vm.define "web02" do |web02|
    web02.vm.box = "opscode-ubuntu-14.04"
    web02.vm.hostname = 'web02'
    web02.vm.box_url = 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box'

    web02.vm.network :private_network, ip: "192.168.56.103"
    web02.vm.network :forwarded_port, guest: 22, host: 10122, id: "ssh"


    web02.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 512]
      v.customize ["modifyvm", :id, "--name", "web02"]
    end
  end

  config.vm.define "db" do |db|
    db.vm.box = "opscode-ubuntu-14.04"
    db.vm.hostname = 'db'
    db.vm.box_url = 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box'
    db.vm.network :private_network, ip: "192.168.56.102"
    db.vm.network :forwarded_port, guest: 22, host: 10222, id: "ssh"

    db.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 512]
      v.customize ["modifyvm", :id, "--name", "db"]
    end
  end

end

