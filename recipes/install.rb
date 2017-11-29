node.default[:java][:jdk_version]                           = 8
node.default[:java][:set_etc_environment]                   = true
node.default[:java][:install_flavor]                        = "oracle"
node.default[:java][:oracle][:accept_oracle_download_terms] = true

include_recipe "java"

case node['platform']
when 'debian', 'ubuntu'
  node[:karamel][:default][:private_ips].each_with_index do |ip, index|
    hostsfile_entry "#{ip}" do
      hostname  "hopsworks#{index}"
      action    :create
      unique    true
    end
  end

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

  node[:karamel][:default][:private_ips].each_with_index do |ip, index|
    hostsfile_entry "#{ip}" do
      hostname  "hopsworks#{index}"
      action    :create
      unique    true
    end
  end

  # Fix bug: https://github.com/mitchellh/vagrant/issues/8115
  bash "restart_network" do
      user "root"
      code <<-EOH
    /etc/init.d/network restart
  EOH
  end
end
