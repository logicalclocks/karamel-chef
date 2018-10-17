
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

default['java']['jdk_version'] = '8'
default['java']['install_flavor'] = 'oracle'
default['java']['jdk']['8']['x86_64']['url'] = 'http://download.oracle.com/otn-pub/java/jdk/8u192-b12/750e1c8617c5452694857ad95c3ee230/jdk-8u192-linux-x64.tar.gz'
default['java']['jdk']['8']['x86_64']['checksum'] = '6d34ae147fc5564c07b913b467de1411c795e290356538f22502f28b76a323c2'
default['java']['oracle']['accept_oracle_download_terms'] = true
