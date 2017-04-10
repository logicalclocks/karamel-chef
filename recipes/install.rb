
node.default[:java][:jdk_version]                           = 8
node.default[:java][:set_etc_environment]                   = true
node.default[:java][:install_flavor]                        = "oracle"
node.default[:java][:oracle][:accept_oracle_download_terms] = true

include_recipe "java"

case node['platform']
when 'debian', 'ubuntu'
  node[:karamel][:default][:private_ips].each_with_index do |ip, index| 
    hostsfile_entry "#{ip}" do
      hostname  "dn#{index}"
      action    :create
      unique    true
    end
  end

when 'redhat', 'centos', 'fedora'

  template "/etc/hosts" do
    source "hosts.erb"
    owner "root"
    group "root"
    mode 0644
  end

# Fix bug: https://github.com/mitchellh/vagrant/issues/8115    
bash "restart_network" do
    user "root"
    code <<-EOF
  /etc/init.d/network restart  
EOF
end


  
end




  
