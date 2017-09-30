

karamel="karamel-0.4.tgz"

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
  not_if { ::File.exists?( "/home/vagrant/karamel-0.4/bin/karamel" ) }
end

bash "public_key" do
    user "vagrant"
    code <<-EOF
cd /home/vagrant/.ssh
cp authorized_keys id_rsa.pub

EOF
  not_if { ::File.exists?( "/home/vagrant/.ssh/id_rsa.pub" ) }
end



template "/home/vagrant/.karamel/conf" do
  source "conf.erb"
  owner "vagrant"
  group "vagrant"
  mode 0751
end

