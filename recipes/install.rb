
node.default.java.jdk_version                         = 8
node.default.java.set_etc_environment                 = true
node.default.java.install_flavor                      = "oracle"
node.default.java.oracle.accept_oracle_download_terms = true

include_recipe "java"


node[:karamel][:default][:private_ips].each_with_index do |ip, index| 
   hostsfile_entry "#{ip}" do
     hostname  "dn#{index}"
     action    :create
     unique    true
   end
end
