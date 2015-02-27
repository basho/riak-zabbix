# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrant file to test riak_zabbix plugin

Vagrant.configure(2) do |config|
  config.vm.box = "phusion/ubuntu-14.04-amd64"
  config.vm.provision "shell", inline: <<-SHELL
sudo apt-get update
sudo apt-get install -y curl jq openjdk-7-jre-headless
curl -s https://packagecloud.io/install/repositories/basho/riak/script.deb | sudo bash
sudo apt-get install -y riak
perl -pi -e "s/^search =.*/search = on/" /etc/riak/riak.conf
sudo apt-get install -y zabbix-agent docker.io
sudo docker pull berngp/docker-zabbix
sudo docker run -d -p 80:80 -p 10051:10051 -p 10052:10052 -p 2812:2812 -P berngp/docker-zabbix
service riak start
ZAB_ID=$(docker ps |grep -v CONTAINER|cut -d " " -f 1|head -1)
ZAB_IP=$(docker inspect $ZAB_ID | jq -r '.[0].NetworkSettings.IPAddress')
perl -pi -e "s/^ServerActive=.*/ServerActive=$ZAB_IP/g" /etc/zabbix/zabbix_agentd.conf
perl -pi -e "s/^Server=.*/Server=$ZAB_IP/g" /etc/zabbix/zabbix_agentd.conf
perl -pi -e "s/^Hostname=.*/Hostname=Riak Host/" /etc/zabbix/zabbix_agentd.conf
cp /vagrant/templates/userparameter_riak.conf /etc/zabbix/zabbix_agentd.conf.d/
riak-admin wait-for-service riak_kv
echo "$(sudo crontab -u riak -l)
### Riak Status Temp File for Zabbix
* * * * * /usr/sbin/riak-admin status > /var/lib/riak/riak-admin_status.new && mv /var/lib/riak/riak-admin_status.new /var/lib/riak/riak-admin_status.tmp" | sudo crontab -u riak -
/usr/sbin/riak-admin status > /var/lib/riak/riak-admin_status.tmp
service zabbix-agent restart
#KEY=$(curl -s -XPOST  -H 'Content-Type: application/json-rpc' http://localhost/zabbix/api_jsonrpc.php -d '{"jsonrpc": "2.0","method": "user.login","params": {"user": "Admin","password": "zabbix"},"id": 1}' | jq -r '.result')

  SHELL
end
