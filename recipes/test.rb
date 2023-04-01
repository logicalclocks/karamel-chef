directory "/home/vagrant" do
  owner "vagrant"
  group "vagrant"
  mode '0755'
  action :create
end

ruby_version = node['test']['ruby_version']

case node['platform']
when 'ubuntu'
  package ['bundler', 'firefox', 'libappindicator3-1', 'fonts-liberation', 'libxss1', 'xdg-utils', 'libreadline-dev', 'zlib1g-dev', 'libgbm1', 'libnspr4', 'libnss3']
  # We are going to install ruby 2.5 using RVM (Ruby version manage)
  template "/tmp/rbenv_install.sh" do
    source "rbenv_install.erb"
    owner "vagrant"
    group "vagrant"
    mode 0755
    variables({
    })
  end
  template "/tmp/rbenv_check.sh" do
    source "rbenv_check.erb"
    owner "vagrant"
    group "vagrant"
    mode 0755
    variables({
    })
  end
  bash "install_ruby_25" do
    user "root"
    group "root"
    retries 5
    code <<-EOH
      # https://linuxize.com/post/how-to-install-ruby-on-ubuntu-18-04/
      # split the install script into install and check so it doesn't return error codes when partially installed
      /tmp/rbenv_install.sh
      #we don't source the .bashrc in here
      export PATH="$HOME/.rbenv/bin:$PATH"
      echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
      eval "$(rbenv init -)"
      echo 'eval "$(rbenv init -)"' >> ~/.bashrc
      /tmp/rbenv_check.sh
      rbenv install #{ruby_version}
      rbenv global #{ruby_version}
    EOH
  end

  remote_file '/tmp/google-chrome.deb' do
    source 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  bash 'install_chrome' do
    ignore_failure true
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-EOH
      dpkg -i google-chrome*.deb
    EOH
  end

when 'centos'
  # We are going to install ruby 2.5 using RVM (Ruby version manage)
  bash "install_ruby_25" do
    user "root"
    group "root"
    retries 5
    code <<-EOH
      # https://linuxize.com/post/how-to-install-ruby-on-centos-7/
      yum -y install curl gpg gcc gcc-c++ make patch autoconf automake bison libffi-devel libtool patch readline-devel sqlite-devel zlib-devel openssl-devel
      gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
      curl -sSL https://rvm.io/mpapis.asc | sudo gpg2 --import -
      curl -sSL https://rvm.io/pkuczynski.asc | sudo gpg2 --import -
      curl -sSL https://get.rvm.io | bash -s stable
      source /etc/profile.d/rvm.sh
      rvm install #{ruby_version}
      rvm use #{ruby_version} --default
    EOH
  end
end

elastic_endpoint=""
elastic_user="#{node['elastic']['opensearch_security']['admin']['username']}"
elastic_pass="#{node['elastic']['opensearch_security']['admin']['password']}"
kibana_endpoint="#{node[:karamel][:default][:private_ips][0]}:#{node[:kibana][:port]}"

elastic_multinode='centos'
elastic_singlenode='ubuntu'

case node['platform']
when elastic_multinode
  elastic_endpoint="#{node[:karamel][:default][:private_ips][2]}:#{node[:elastic][:port]}"
  epipe_host = "#{node[:karamel][:default][:private_ips][1]}"

when elastic_singlenode
elastic_endpoint="#{node[:karamel][:default][:private_ips][0]}:#{node[:elastic][:port]}"
epipe_host = "#{node[:karamel][:default][:private_ips][0]}"
end

# Copy the environment configuration in the test directory
template "#{node['test']['hopsworks']['test_dir']}/.env" do
  source "rspec_env.erb"
  owner "vagrant"
  group "vagrant"
  mode 0755
  variables({
    'elastic_endpoint' => elastic_endpoint,
    'kibana_endpoint' => kibana_endpoint,
    'elastic_user' => elastic_user,
    'elastic_pass' => elastic_pass,
    'epipe_host' => epipe_host
  })
end

# Delete form workspace previous test results
file "#{node['test']['hopsworks']['report_dir']}/#{node['platform']}.xml" do
  action :delete
end

# If it_tests should be run, prepare it test resources
if node['test']['hopsworks']['it']
  include_recipe "karamel::it_tests"
end

# Install dependencies and execute tests
case node['platform']
when 'ubuntu'
  bash "unit_tests" do
    user "root"
    ignore_failure true
    cwd node['test']['hopsworks']['base_dir']
    timeout node['karamel']['test_timeout']
    # Run hopsworks unit tests
    code <<-EOH
      start=`date +%s`
      start_time=`date`
      echo "start running unit test: $start_time"
      set -e
      mkdir -pm 777 #{node['test']['hopsworks']['report_dir']}/ut
      mvn test -Dmaven.test.failure.ignore=true
      end=`date +%s`
      runtime=$((end-start))
      echo "Running time for unit test: $runtime"
      find . -name "*.xml" | grep "surefire-reports" | xargs cp -t #{node['test']['hopsworks']['report_dir']}/ut
    EOH
  end

  bash "dependencies_tests" do
    user "root"
    ignore_failure true
    cwd node['test']['hopsworks']['test_dir']
    timeout node['karamel']['test_timeout']
    environment ({'PATH' => "#{ENV['PATH']}:/usr/bin/ruby2.5:/srv/hops/mysql/bin",
                  'LD_LIBRARY_PATH' => "#{ENV['LD_LIBRARY_PATH']}:/srv/hops/mysql/lib",
                  'JAVA_HOME' => "/usr/lib/jvm/default-java"})
    code <<-EOH
      start=`date +%s`
      start_time=`date`
      echo "start running dependencies test: $start_time"
      bundle install
      /srv/hops/anaconda/anaconda/bin/python lambo_rspec.py -proc 4 -out #{node['test']['hopsworks']['report_dir']} -os #{node['platform']}
      end=`date +%s`
      runtime=$((end-start))
      echo "Running time for dependencies test: $runtime"
    EOH
  end

  # Run Selenium tests
  bash 'selenium-firefox' do
    user 'root'
    ignore_failure true
    cwd node['test']['hopsworks']['base_dir']
    environment ({'HOPSWORKS_URL' => 'https://localhost:8181/hopsworks',
                  'HEADLESS' => "true",
                  'DB_HOST' => "127.0.0.1",
                  'BROWSER' => "firefox"})
    code <<-FIREFOX
      start=`date +%s`
      start_time=`date`
      echo "start running selenium test: $start_time"
      mvn clean install -P-web,mysql -Dmaven.test.failure.ignore=true
      cd hopsworks-IT/target/failsafe-reports
      for file in *.xml ; do cp $file #{node['test']['hopsworks']['report_dir']}/firefox-${file} ; done
      end=`date +%s`
      runtime=$((end-start))
      echo "Running time for selenium firefox test: $runtime"
    FIREFOX
    only_if { node['test']['hopsworks']['frontend'] }
  end

  bash 'selenium-chrome' do
    user 'root'
    ignore_failure true
    cwd node['test']['hopsworks']['base_dir']
    environment ({'HOPSWORKS_URL' => 'https://localhost:8181/hopsworks',
                  'HEADLESS' => "true",
                  'DB_HOST' => "127.0.0.1",
                  'BROWSER' => "chrome"})
    code <<-CHROME
      start=`date +%s`
      start_time=`date`
      echo "start running selenium chrome test: $start_time"
      mvn clean install -P-web,mysql -Dmaven.test.failure.ignore=true
      cd hopsworks-IT/target/failsafe-reports
      for file in *.xml ; do cp $file #{node['test']['hopsworks']['report_dir']}/chrome-${file} ; done
      end=`date +%s`
      runtime=$((end-start))
      echo "Running time for selenium chrome test: $runtime"
    CHROME
    only_if { node['test']['hopsworks']['frontend'] }
  end

when 'centos'
  bash "dependencies_tests" do
    user "root"
    ignore_failure true
    timeout node['karamel']['test_timeout']
    cwd node['test']['hopsworks']['test_dir']
    environment ({'PATH' => "/usr/local/rvm/gems/ruby-#{ruby_version}/bin:/usr/local/rvm/gems/ruby-#{ruby_version}@global/bin:/usr/local/rvm/rubies/ruby-#{ruby_version}/bin:/usr/local/bin:/srv/hops/mysql/bin:#{ENV['PATH']}",
              'LD_LIBRARY_PATH' => "#{ENV['LD_LIBRARY_PATH']}:/srv/hops/mysql/lib",
              'HOME' => "/home/vagrant",
              'JAVA_HOME' => "/usr/lib/jvm/java"})

    code <<-EOH
      bundle install
      /srv/hops/anaconda/anaconda/bin/python lambo_rspec.py -proc 4 -out #{node['test']['hopsworks']['report_dir']} -os #{node['platform']}
    EOH
  end
end
