

bash "run_karamel" do
    user "vagrant"
    code <<-EOF
cd /home/vagrant/karamel-0.3
./bin/karamel -launch /home/vagrant/cluster.yml

EOF
end
