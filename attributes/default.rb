
default['karamel']['version']         = "0.5"
default['karamel']['download_url']    = "http://www.karamel.io/sites/default/files/downloads/karamel-#{node['karamel']['version']}.tgz"

default['karamel']['download_file']    = "#{Chef::Config['file_cache_path']}/#{File.basename(node['karamel']['download_url'])}"
default['karamel']['base_dir']        = "/home/vagrant/karamel-#{node['karamel']['version']}"
default['karamel']['bin_file']        = "#{node['karamel']['base_dir']}/bin/karamel"
default['karamel']['output_dir']      = "/home/vagrant/.karamel"

default['karamel']['run_timeout']     = 36000

default['cluster_def']                = "/home/vagrant/cluster.yml"
default['region']                     = "se"

# Testing attributes
default['test']['hopsworks']['repo']        = "https://github.com/hopshadoop/hopsworks"
default['test']['hopsworks']['branch']      = "master"

default['test']['hopsworks']['base_dir']    = "/home/vagrant/hopsworks"
default['test']['hopsworks']['test_dir']    = "#{node['test']['hopsworks']['base_dir']}/hopsworks-ear/test"
default['test']['hopsworks']['report_dir']      = "/home/vagrant/test_report"

default['test']['anaconda_cache']['version'] = "5.0.1"

default['java']['jdk_version'] = '8'
default['java']['install_flavor'] = 'oracle'
default['java']['jdk']['8']['x86_64']['url'] = 'http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jdk-8u181-linux-x64.tar.gz'
default['java']['jdk']['8']['x86_64']['checksum'] = '1845567095bfbfebd42ed0d09397939796d05456290fb20a83c476ba09f991d3'
default['java']['oracle']['accept_oracle_download_terms'] = true
