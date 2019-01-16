include_recipe "java"

node[:karamel][:default][:private_ips].each_with_index do |ip, index|
  hostsfile_entry "#{ip}" do
    hostname  "hopsworks#{index}.logicalclocks.com"
    aliases   ["hopsworks#{index}"]
    comment   "Created by karamel-chef"
    action    :create
    unique    true
  end
end

case node['platform']
when 'debian', 'ubuntu'

  ### BEGIN OF HACK

  # This is a hack to reduce the deployment time of the testing machines.
  # The default APT servers are the US ones. The next few likes overwrite
  # the mirror list putting on top the one of your region (Sweden by default)

  # Delete old sources.list file
  file "/etc/apt/sources.list" do
    user "root"
    action :delete
  end

  # Put the new one in
  template "/etc/apt/sources.list" do
    source "sources.list.erb"
    owner "root"
    group "root"
    mode   0644
  end

  # Update the repository list
  bash "update_repolist" do
    user "root"
    code <<-EOH
      apt update
    EOH
  end

  ### END OF HACK

when 'redhat', 'centos', 'fedora'



  # Fix bug: https://github.com/mitchellh/vagrant/issues/8115
  bash "restart_network" do
      user "root"
      code <<-EOH
    /etc/init.d/network restart
  EOH
  end
end
