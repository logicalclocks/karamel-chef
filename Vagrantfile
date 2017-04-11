
Vagrant.configure("2") do |config|

   config.ssh.insert_key = false
 
  config.vm.define "dn0", primary: true do |dn0|
    dn0.vm.box = "bento/ubuntu-16.04"
    dn0.vm.hostname = 'dn0'

    dn0.vm.network :private_network, ip: "192.168.56.101"
    dn0.vm.network :forwarded_port, guest: 22, host: 10122, id: "ssh"
    # MySQL Server
    dn0.vm.network(:forwarded_port, {:guest=>3306, :host=>8181})
    # karamel http
    dn0.vm.network(:forwarded_port, {:guest=>9090, :host=>46535})     
    # Hopsworks http
    dn0.vm.network(:forwarded_port, {:guest=>8080, :host=>60247})     
    # Glassfish debug port
    dn0.vm.network(:forwarded_port, {:guest=>9009, :host=>9191})
    # Glassfish admin UI
    dn0.vm.network(:forwarded_port, {:guest=>4848, :host=>25189})         
    # Yarn RM 
    dn0.vm.network(:forwarded_port, {:guest=>8088, :host=>52618})
    # Kibana
    dn0.vm.network(:forwarded_port, {:guest=>5601, :host=>27726})
    # Grafana Webserver
    dn0.vm.network(:forwarded_port, {:guest=>3000, :host=>22259})
    # Nodemanager
    dn0.vm.network(:forwarded_port, {:guest=>8083, :host=>20482})
    # Influx DB admin (because of clash with nodemanager)
    dn0.vm.network(:forwarded_port, {:guest=>8084, :host=>37033})
    # Influx DB REST API
    dn0.vm.network(:forwarded_port, {:guest=>8086, :host=>60122})
    # Graphite Endpoint
    dn0.vm.network(:forwarded_port, {:guest=>2003, :host=>56968})


    dn0.vm.provision "file", source: "cluster.yml", destination: "cluster.yml"
    dn0.vm.provision "file", source: "~/.vagrant.d/insecure_private_key", destination: "~/.ssh/id_rsa"    
    dn0.vm.provision "shell", inline: "cp /home/vagrant/.ssh/authorized_keys /home/vagrant/.ssh/id_rsa.pub && sudo chown vagrant:vagrant /home/vagrant/.ssh/id_rsa.pub"
    
    dn0.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 16048]
      v.customize ["modifyvm", :id, "--name", "dn0"]      
    end

    dn0.vm.provision :chef_solo do |chef|
        chef.cookbooks_path = "cookbooks"
        chef.json = {
          "karamel" => {
	    "default" =>      { 
              "private_ips" => ["192.168.56.101"]
	    },
          },
        }
        chef.add_recipe "karamel::install"
        chef.add_recipe "karamel::default"     
        chef.add_recipe "karamel::run"     
      end
    
  end

end

