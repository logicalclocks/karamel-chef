name             "karamel"
maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
license          "Apache v2.0"
description      "Installs/Configures Karamel."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
source_url       "https://github.com/hopshadoop/karamel-chef"


%w{ ubuntu debian centos rhel }.each do |os|
  supports os
end

depends 'java'

depends 'hostsfile'

recipe  "karamel::install", "Installs Karamel"

recipe  "karamel::default", "Configures and starts karamel."


#attribute "karamel/port",
#          :description => "Port that webserver will listen on",
#          :type => 'string'

