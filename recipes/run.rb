bash "run_karamel" do
    user "vagrant"
    timeout 36000
    code <<-EOF
    set -e
      cd #{node['karamel']['base_dir']}
      ./bin/karamel -headless -launch #{node['cluster_def']}
    EOF
end
