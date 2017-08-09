bash "run_karamel" do
    user "vagrant"
    timeout 36000
    code <<-EOF
    set -e
    cd /home/vagrant/karamel-0.3
    ./bin/karamel -headless -launch /home/vagrant/cluster.yml 
EOF
end


package "git"

package "maven"

bash "hopsworks_tests" do
    user "root"
    timeout 36000
    code <<-EOF
    set -e
    cd /home/vagrant
    git clone git@github.com:hopshadoop/hopsworks.git
        

EOF
end
