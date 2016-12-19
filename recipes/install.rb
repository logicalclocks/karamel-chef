
node.default.java.jdk_version                         = 8
node.default.java.set_etc_environment                 = true
node.default.java.install_flavor                      = "oracle"
node.default.java.oracle.accept_oracle_download_terms = true

include_recipe "java"

karamel="karamel-0.3.tgz"

kf="/home/vagrant/#{karamel}"

remote_file kf do
  source "http://www.karamel.io/sites/default/files/downloads/#{karamel}"
  mode 0755
  action :create
end



bash "unpack_karamel" do
    user "root"
    code <<-EOF
cd /home/vagrant
mkdir .karamel
chown vagrant .karamel
tar -xzf #{kf}
chown -R vagrant karamel*

EOF
  not_if { ::File.exists?( "/home/vagrant/karamel-0.3/bin/karamel" ) }
end



template "/home/vagrant/.karamel/conf" do
  source "conf.erb"
  owner "vagrant"
  group "vagrant"
  mode 0751
end
