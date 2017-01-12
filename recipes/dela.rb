
# https://www.cyberciti.biz/faq/linux-traffic-shaping-using-tc-to-control-http-traffic/
# TO REMOVE LATENCY:
# tc qdisc del dev eth0 root netem
# tc -s qdisc

bash "add_ip_latency" do
    user "root"
    code <<-EOF
    tc qdisc add dev eth1 root netem delay 200ms
EOF
end


