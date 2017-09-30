bash "run_karamel" do
    user "vagrant"
    timeout 36000
    code <<-EOF
    set -e
    cd /home/vagrant/karamel-0.4
    ./bin/karamel -headless -launch /home/vagrant/cluster.yml
EOF
end

package ['git', 'maven']

git '/home/vagrant/hopsworks' do
   repository 'https://github.com/hopshadoop/hopsworks.git'
   revision 'master'
   action :sync
   user 'root'
end
