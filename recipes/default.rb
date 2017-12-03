# Download Karamel on the machine
remote_file node['karamel']['download_file'] do
  source node['karamel']['download_url']
  mode 0755
  action :create
end

# Unpack Karamel
bash "Unpack_Karamel" do
  user "vagrant"
  code <<-EOF
    mkdir #{node['karamel']['output_dir']}
    tar -xzf #{node['karamel']['download_file']} -C /home/vagrant
  EOF
  not_if { ::File.exists?( node['karamel']['bin_file'] ) }
end

# Add public key for testing machine
bash "public_key" do
  user "vagrant"
  code <<-EOF
    cd /home/vagrant/.ssh
    cp authorized_keys id_rsa.pub
  EOF
  not_if { ::File.exists?( "/home/vagrant/.ssh/id_rsa.pub" ) }
end

# Add default configuration file
template "#{node['karamel']['output_dir']}/conf" do
  source "conf.erb"
  owner "vagrant"
  group "vagrant"
  mode 0751
end
