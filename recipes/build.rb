package ['git', 'maven']

# In EE hopsworks is copied from the local node into the VM with the vagrantfile
if node['build']['test']['community']
  # Clone Hopsworks
  git node['test']['hopsworks']['base_dir']  do
    repository node['test']['hopsworks']['repo']
    revision node['test']['hopsworks']['branch']
    user "vagrant"
    group "vagrant"
    action :sync
  end
end

# Create chef-solo cache dir
directory '/tmp/chef-solo' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

#EE default flags
ubuntu_build_flags = "-Ptesting,web"
centos_build_flags = "-Pkube,noSeleniumTest,testing"
if node['build']['test']['community']
  centos_build_flags = "-Pweb,testing,noSeleniumTest"
  ubuntu_build_flags = "-Pweb,testing"
end

case node['platform_family']
when "debian"
  package ['npm']
  npm_package 'bower' do
    user 'root'
  end

  npm_package 'grunt' do
    user 'root'
  end

  npm_package 'bower-npm-resolver' do
    user 'root'
  end

  bash 'root_hack' do
    user 'root'
    group 'root'
    code <<-EOH
      echo '{ "allow_root": true }' > /root/.bowerrc
    EOH
  end

  bash 'update-npm' do
    user 'root'
    group 'root'
    code <<-EOH
      npm install -g n
      n 11.15.0
      npm install -g npm@6.9.0
    EOH
  end

  # Build HopsWorks
  bash 'build-hopsworks' do
    user 'root'
    group 'root'
    cwd node['test']['hopsworks']['base_dir']
    code <<-EOF
      cp /home/vagrant/.m2/settings.xml /root/.m2/
      mvn clean install #{ubuntu_build_flags} -DskipTests
      VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec)
      mv hopsworks-ear/target/hopsworks-ear.ear /tmp/chef-solo/hopsworks-ear\:$VERSION-$VERSION.ear
      mv hopsworks-ca/target/hopsworks-ca.war /tmp/chef-solo/hopsworks-ca\:$VERSION-$VERSION.war
      mv hopsworks-web/target/hopsworks-web.war /tmp/chef-solo/hopsworks-web\:$VERSION-$VERSION.war
    EOF
  end

when 'rhel'
  remote_file '/tmp/apache-maven-3.6.3-bin.tar.gz' do
    source 'https://downloads.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  bash 'extract-maven' do
    user 'root'
    group 'root'
    code <<-EOF
      tar xf /tmp/apache-maven-3.6.3-bin.tar.gz -C /opt
      ln -s /opt/apache-maven-3.6.3 /opt/maven
    EOF
  end

  bash 'build-hopsworks' do
    user 'root'
    group 'root'
    cwd node['test']['hopsworks']['base_dir']
    code <<-EOF
      cp /home/vagrant/.m2/settings.xml /root/.m2/
      /opt/maven/bin/mvn clean install #{centos_build_flags} -DskipTests
      VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive exec:exec)
      mv hopsworks-ear/target/hopsworks-ear.ear /tmp/chef-solo/hopsworks-ear\:$VERSION-$VERSION.ear
      mv hopsworks-ca/target/hopsworks-ca.war /tmp/chef-solo/hopsworks-ca\:$VERSION-$VERSION.war
    EOF
  end
end
