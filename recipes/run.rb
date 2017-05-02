bash "run_karamel" do
    user "vagrant"
    timeout 36000
    code <<-EOF
cd /home/vagrant/karamel-0.3
./bin/karamel -headless -launch /home/vagrant/cluster.yml 

EOF
end
