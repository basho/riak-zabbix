# Monitoring Riak with Zabbix

This document describes how to use the files included in this repository to monitor your Riak infrastructure.

Here is a description of the following components:


## riak_stats.py

This script should be placed in /usr/local/bin.  It performs the following actions:

1. collects information from the Riak stats JSON interface
2. compiles those stats in a format that is acceptable for zabbix_sender
3. writes a temporary file to /tmp/riak_stats.txt
4. calls zabbix sender program to send data to zabbix server



## riak.conf

This file should be placed in /etc/zabbix-agent.d/riak.conf.  All it does is define a UserParameter to call the riak_stats.py script:

	UserParameter=riak.collector, /usr/local/bin/riak_stats.py
	
## riak_zabbix_template.xml


Importing this file will create a Riak template in your Zabbix installation with a number of different Zabbix items and graphs.  Link it to your Riak servers to start collect metrics.	