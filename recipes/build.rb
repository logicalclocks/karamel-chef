# Install NPM
include_recipe "nodejs"

package ['git', 'maven']

# Clone Hopsworks
git node['test']['hopsworks']['base_dir']  do
  repository node['test']['hopsworks']['repo']
  revision node['test']['hopsworks']['branch']
  user "vagrant"
  group "vagrant"
  action :sync
end

# Build hopsworks
bash 'build-hopsworks' do
  user 'vagrant'
  group 'vagrant'
  environment ({'HOME' => '/home/vagrant'})
  cwd node['test']['hopsworks']['base_dir']
  code <<-EOF
    mvn clean install -P-web -Dmaven.test.skip=true
  EOF
end

# Create chef-solo cache dir
directory '/tmp/chef-solo' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# Copy artifacts to cache location to be deployed
remote_file '/tmp/chef-solo/hopsworks-ear-test.ear' do
  source "file:///#{node['test']['hopsworks']['ear']}"
  mode "777"
  action :create_if_missing
end

remote_file '/tmp/chef-solo/hopsworks-ca-test.war' do
  source "file:///#{node['test']['hopsworks']['ca']}"
  mode "777"
  action :create_if_missing
end
