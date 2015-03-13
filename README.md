riak_zabbix
===========

#### Zabbix plugin for Riak

#####Contains:

* userparameter_riak.conf
	* Agent Configuration

* zabbix_agent_template_riak.xml
	* Templates for:
		* Agent Items
		* Graphs
		* Triggers

##### Usage:

Install userparameter_riak.conf to zabbix agent conf dir:

	cp templates/userparameter_riak.conf /etc/zabbix/zabbix_agentd.conf.d/

Add the following line to riak's crontab entry*:

	sudo crontab -u riak -e

	* * * * * /usr/sbin/riak-admin status > /var/lib/riak/riak-admin_status.new && mv /var/lib/riak/riak-admin_status.new /var/lib/riak/riak-admin_status.tmp

Restart the zabbix agent

\* Why crontab, and why so ugly?? We're using crontab so the zabbix client doesn't have to run under escalated privileges. The hacky ```>``` then ```mv``` is to eliminate the agent from attempting to read the ```tmp``` file *while* riak-admin is running, causing erroneous ```NULL``` results.

##### Building:

The items are listed in the ```stats_file```, add and remove those as needed. Execute ```./build_templates.sh``` to rebuild agent config and template xml file.

The logic & custom graphs are defined in the build_template.sh script. Here is the code at this moment, for an idea how they're broken up:

	for graph in $(grep '_median$' $STAT_LIST); do
	  title=${graph//_median/}
	  items=$(grep "^$title" $STAT_LIST)

	  print_graph "$title" items[@]

	  outliers=()
	  possible_outliers=($title"_95" $title"_99" $title"_100")
	  for outlier in ${possible_outliers[@]}; do
	    if grep $outlier $STAT_LIST > /dev/null; then
	      outliers+=($outlier)
	    fi
	  done
	  print_graph "$title""_outliers" outliers[@]

	done

	for graph in $(grep '_gets_' $STAT_LIST); do
	  title=${graph//_gets_/_gets_and_puts_}
	  items=( $graph ${graph//_gets_/_puts_} )

	  print_graph "$title" items[@]

	done

	items=( search_index_throughput_count search_query_throughput_count )
	print_graph "search-query_index_throughput" items[@]

Execute ```build_templates.sh``` to rebuild the userparameter and xml files.

##### Testing

The included ```Vagrantfile``` will spin up an ubuntu VM, install Riak & Docker, and then pull the ```berngp/docker-zabbix``` [https://github.com/berngp/docker-zabbix](https://github.com/berngp/docker-zabbix) image to test the templates.

###### Example:

	vagrant up
	vagrant ssh -- -L8080:localhost:80 -L8087:localhost:8087

Visit [http://localhost:8080/zabbix/](http://localhost:8080/zabbix/)

Log into Zabbix (default user is `Admin`, password is `zabbix`); Go to Configuration -> Templates, and in the upper right, select 'Import', and choose the ```templates/zabbix_agent_template_riak.xml``` template.

Create a host with the vagrant VM's ```docker0``` ip ( i.e. ```172.17.42.1```), and the Riak template using the following steps:

1. Run `ifconfig | grep -A1 'docker0' | grep -v docker0 | cut -d \  -f 12 | cut -d : -f 2` to quickly find the ip for the new host.
2. Navigate to Configuration -> Hosts -> Create Host in the Zabbix interface.
3. Name the host something like `Riak Zabbix`.
4. Add the group `Zabbix servers` in the Groups field.
5. In the Agent interfaces field, copy the docker0 ip from step 1 into the IP address section.
6. Click the Templates tab.
7. In the search box, type Riak and select the auto-suggested template that was previously added.
8. Click the `add` link below the search box.
9. Click the `Add` button to finish adding the host.

Perform some operations via Riak's protobuf interface to generate stats. To view an example graph, follow these steps:

1. Navigate to Monitoring -> Graphs.
2. In the Group / Host / Graph selection in the top right, select `Zabbix Servers`, `Riak Zabbix`, and `Node Put FSM Time`.
3. Click the plus sign in the upper right to add this graph to favorites.


