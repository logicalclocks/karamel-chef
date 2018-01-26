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

# Create chef-solo cache dir
directory '/tmp/chef-solo' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# Build HopsWorks
bash 'build-hopsworks' do
   user 'root'
   group 'root'
   cwd node['test']['hopsworks']['base_dir']
   code <<-EOF
     mvn clean install -P-web -Dmaven.test.skip=true
     VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec)
     mv hopsworks-ear/target/hopsworks-ear.ear /tmp/chef-solo/hopsworks-ear-$VERSION.ear
     mv hopsworks-ca/target/hopsworks-ca.war /tmp/chef-solo/hopsworks-ca-$VERSION.war
   EOF
end
