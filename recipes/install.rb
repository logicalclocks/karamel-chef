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

bash 'set-hostname' do
    user "root"
    group "root"
    code <<-EOH
      hostnamectl set-hostname #{node[:karamel][:hostname]}
    EOH
    not_if {node[:karamel][:hostname].eql?("")}
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

  # ubuntu/bionic64 box doesn't have password authentication enabled for SSH
  # Which is useful in a development environment (And we have IT tests depending on it)
  bash "enable_pwd_auth" do
    user "root"
    code <<-EOH
      sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
      systemctl restart sshd
    EOH
  end
end

bash "Add swap" do
  user "root"
  group "root"
  ignore_failure true
  code <<-EOF
       fallocate -l 2G /swapfile
       chmod 600 /swapfile
       mkswap /swapfile
       swapon /swapfile
       echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
  EOF
  not_if 'swapon --bytes | grep NAME'
end

bash "Temporary fix expired Let's Encrypt CA" do
  user "root"
  group "root"
  code <<-EOF
    sed -ie '/DST Root CA X3/,+19d' /opt/chef/embedded/ssl/certs/cacert.pem
  EOF
end