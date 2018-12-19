case node['platform']
when 'ubuntu'
  package ['bundler']
when 'centos'
  # Centos comes with a pre world-war-1 version of ruby
  # We are going to install ruby 2.4 using RVM (Ruby version manage)
  # which, of course, is not in the repo.
  bash "install_ruby_24" do
    user "root"
    group "root"
    code <<-EOH
      yum install gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel sqlite-devel
      gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
      curl -sSL https://get.rvm.io | bash -s stable
      source /etc/profile.d/rvm.sh
      rvm reload
      rvm install 2.4.1
    EOH
  end
end

elastic_endpoint=""
case node['platform']
when 'ubuntu'
  elastic_endpoint="#{node[:karamel][:default][:private_ips][2]}:9200"
when 'centos'
  elastic_endpoint="#{node[:karamel][:default][:private_ips][0]}:9200"
end

# Copy the environment configuration in the test directory
template "#{node['test']['hopsworks']['test_dir']}/.env" do
  source "rspec_env.erb"
  owner "vagrant"
  group "vagrant"
  mode 0755
  variables(lazy {
    h = {}
    h['elastic_endpoint'] = elastic_endpoint
    h
  })
end

# Delete form workspace preivous test results
file "#{node['test']['hopsworks']['report_dir']}/#{node['platform']}.xml" do
  action :delete
end

# Install dependencies and execute tests
case node['platform']
when 'ubuntu'
  bash "dependencies_tests" do
    user "root"
    ignore_failure true
    cwd node['test']['hopsworks']['test_dir']
    timeout node['karamel']['test_timeout']
    environment ({'PATH' => "#{ENV['PATH']}:/home/vagrant/.gem/ruby/2.3.0/bin:/srv/hops/mysql/bin",
                  'LD_LIBRARY_PATH' => "#{ENV['LD_LIBRARY_PATH']}:/srv/hops/mysql/lib",
                  'JAVA_HOME' => "/usr/lib/jvm/default-java"})
    code <<-EOH
      bundle install
      rspec --format RspecJunitFormatter --out #{node['test']['hopsworks']['report_dir']}/ubuntu.xml
    EOH
  end

when 'centos'
  bash "dependencies_tests" do
    user "root"
    ignore_failure true
    timeout node['karamel']['test_timeout']
    cwd node['test']['hopsworks']['test_dir']
    environment ({'PATH' => "#{ENV['PATH']}:/usr/local/bin:/srv/hops/mysql/bin",
              'LD_LIBRARY_PATH' => "#{ENV['LD_LIBRARY_PATH']}:/srv/hops/mysql/lib",
              'HOME' => "/home/vagrant",
              'GEM_PATH' => "/usr/local/rvm/gems/ruby-2.4.1:/usr/local/rvm/gems/ruby-2.4.1@global",
              'GEM_HOME' => "/usr/local/rvm/gems/ruby-2.4.1",
              'JAVA_HOME' => "/usr/lib/jvm/java"})
    code <<-EOH
      set -e
      rvm use 2.4.1
      gem install bundler
      bundle install
      rspec --format RspecJunitFormatter --out #{node['test']['hopsworks']['report_dir']}/centos.xml
    EOH
  end
end
