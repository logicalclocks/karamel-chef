name             "karamel"
maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
license          "Apache v2.0"
description      "Installs/Configures Karamel."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"
source_url       "https://github.com/hopshadoop/karamel-chef"
issues_url       "https://github.com/hopshadoop/karamel-chef/issues"


%w{ ubuntu debian centos rhel }.each do |os|
  supports os
end

depends 'java'
depends 'hostsfile'
depends 'nodejs'
depends 'hops'
depends 'elastic'
depends 'hopslog'

recipe  "karamel::install", "Installs Karamel"
recipe  "karamel::default", "Configures and starts karamel."
recipe  "karamel::run", "Runs karamel."
recipe  "karamel::build", "Builds HopsWorks locally"
recipe  "karamel::test", "Run HopsWorks tests"

recipe  "karamel::dela", "Adds IP latencies for all IP network traffic."

attribute "karamel/timeout",
          :description => "Timeout for completing karamel. Default: 36000 (s) - 10 hrs",
          :type => 'string'

