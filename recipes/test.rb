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
      curl -sSL https://rvm.io/mpapis.asc | gpg --import -
      curl -L get.rvm.io | bash -s stable
      source /etc/profile.d/rvm.sh
      rvm reload
      rvm install 2.4.1
    EOH
  end
end


# Copy the environment configuration in the test directory
template "#{node['test']['hopsworks']['test_dir']}/.env" do
  source "rspec_env.erb"
  owner "vagrant"
  group "vagrant"
  mode 0755
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
    environment ({'PATH' => "#{ENV['PATH']}:/home/vagrant/.gem/ruby/2.3.0/bin:/srv/hops/mysql/bin",
                  'LD_LIBRARY_PATH' => "#{ENV['LD_LIBRARY_PATH']}:/srv/hops/mysql/lib"})
    code <<-EOH
      bundle install
      rspec --format RspecJunitFormatter --out #{node['test']['hopsworks']['report_dir']}/ubuntu.xml
    EOH
  end

when 'centos'
  bash "dependencies_tests" do
    user "root"
    ignore_failure true
    cwd node['test']['hopsworks']['test_dir']
    environment ({'PATH' => "#{ENV['PATH']}:/usr/local/bin:/srv/hops/mysql/bin",
                  'LD_LIBRARY_PATH' => "#{ENV['LD_LIBRARY_PATH']}:/srv/hops/mysql/lib"})
    code <<-EOH
      set -e
      source /usr/local/rvm/scripts/rvm
      rvm use 2.4.1
      gem install bundler
      bundle install
      rspec --format RspecJunitFormatter --out #{node['test']['hopsworks']['report_dir']}/centos.xml
    EOH
  end
end
