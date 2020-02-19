include_attribute "elastic"
#asdf
default['karamel']['version']         = "0.6"
default['karamel']['download_url']    = "http://www.karamel.io/sites/default/files/downloads/karamel-#{node['karamel']['version']}.tgz"

default['karamel']['download_file']    = "#{Chef::Config['file_cache_path']}/#{File.basename(node['karamel']['download_url'])}"
default['karamel']['base_dir']        = "/home/vagrant/karamel-#{node['karamel']['version']}"
default['karamel']['bin_file']        = "#{node['karamel']['base_dir']}/bin/karamel"
default['karamel']['output_dir']      = "/home/vagrant/.karamel"

default['karamel']['run_timeout']     = 36000
default['karamel']['test_timeout']    = 30600

default['cluster_def']                = "/home/vagrant/cluster.yml"
default['region']                     = "se"

# Testing attributes
default['test']['hopsworks']['repo']        = "https://github.com/logicalclocks/hopsworks"
default['test']['hopsworks']['branch']      = "master"

default['test']['hopsworks']['base_dir']    = "/home/vagrant/hopsworks"
default['test']['hopsworks']['test_dir']    = "#{node['test']['hopsworks']['base_dir']}/hopsworks-IT/src/test/ruby"
default['test']['hopsworks']['report_dir']  = "/home/vagrant/test_report"
default['test']['hopsworks']['frontend']    = true
default['test']['hopsworks']['it']          = false

default['java']['jdk_version'] = '8'
default['java']['install_flavor'] = 'openjdk'
