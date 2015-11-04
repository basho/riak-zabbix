#!/bin/bash

STAT_LOC=/var/lib/riak/riak-admin_status.tmp
USERPREF=./templates/userparameter_riak.conf
TPL=./templates/zabbix_agent_template_riak.xml
STAT_LIST=stat_list

COLORS=(
C80000
00C800
0000C8
00C8C8
C8C800
C800C8
)


cat <<EOF > $USERPREF
##
## Riak Zabbix Stats
##
## Relys on riak or root cron entry:
##
##     * * * * * /usr/sbin/riak-admin status > /var/lib/riak/riak-admin_status.tmp
##
EOF

for STAT in $(cat $STAT_LIST); do
  echo "UserParameter=Riak.$STAT,( grep '^$STAT :' $STAT_LOC || echo \"notfound : NULL\" ) | awk {'print \$3'}" >> $USERPREF
done

echo "UserParameter=Riak.process_beam.smp,ps -Ao comm= | grep beam.smp | wc -l" >> $USERPREF
echo "UserParameter=Riak.process_epmd,ps -Ao comm= | grep beam.smp | wc -l" >> $USERPREF

function pp_name(){
  IFS='_' read -a words <<< "$1"
  local pp_words=()
  for word in ${words[@]}; do
    pp_words+=($(echo ${word:0:1} | tr  '[a-z]' '[A-Z]')${word:1})
  done
  echo ${pp_words[@]} | sed -e 's/Time$/Time(ms)/'
}

print_tpl_head(){
  cat <<EOX1 > $TPL
<?xml version="1.0" encoding="UTF-8"?>
<zabbix_export>
    <version>2.0</version>
    <date>$(date +"%FT%TZ")</date>
    <groups>
        <group>
            <name>Templates</name>
        </group>
    </groups>
    <templates>
        <template>
            <template>Riak</template>
            <name>Riak</name>
            <groups>
                <group>
                    <name>Templates</name>
                </group>
            </groups>
            <applications>
                <application>
                    <name>Riak</name>
                </application>
            </applications>
            <items>
EOX1
}

print_tpl_item(){
  name=$1
  nice_name=$(pp_name $name)
  print_raw_tpl_item "Riak.$name" "$nice_name"
}

print_raw_tpl_item(){
  ITEM=$1
  title=$2
  cat <<EOITEM >> $TPL
                <item>
                    <name>$title</name>
                    <type>0</type>
                    <snmp_community/>
                    <multiplier>0</multiplier>
                    <snmp_oid/>
                    <key>$ITEM</key>
                    <delay>60</delay>
                    <history>7</history>
                    <trends>365</trends>
                    <status>0</status>
                    <value_type>3</value_type>
                    <allowed_hosts/>
                    <units/>
                    <delta>0</delta>
                    <snmpv3_securityname/>
                    <snmpv3_securitylevel>0</snmpv3_securitylevel>
                    <snmpv3_authpassphrase/>
                    <snmpv3_privpassphrase/>
                    <formula>1</formula>
                    <delay_flex/>
                    <params/>
                    <ipmi_sensor/>
                    <data_type>0</data_type>
                    <authtype>0</authtype>
                    <username/>
                    <password/>
                    <publickey/>
                    <privatekey/>
                    <port/>
                    <description>Riak $title</description>
                    <inventory_link>0</inventory_link>
                    <applications>
                        <application>
                            <name>Riak</name>
                        </application>
                    </applications>
                    <valuemap/>
                </item>
EOITEM
}

print_post_items(){
  cat <<EOPITEM >> $TPL
            </items>
            <discovery_rules/>
            <macros/>
            <templates/>
            <screens/>
        </template>
    </templates>
    <triggers>
EOPITEM
}

print_trigger(){
  cat <<EOTRIG >> $TPL
        <trigger>
            <expression>$1</expression>
            <name>$2</name>
            <url/>
            <status>0</status>
            <priority>4</priority>
            <description/>
            <type>0</type>
            <dependencies/>
        </trigger>
EOTRIG
}

print_post_trigger(){
  cat <<EOPTRIG >> $TPL
    </triggers>
    <graphs>
EOPTRIG
}

print_graph_head(){
  cat <<EOGHEAD >> $TPL
        <graph>
            <name>$1</name>
            <width>900</width>
            <height>200</height>
            <yaxismin>0.0000</yaxismin>
            <yaxismax>100.0000</yaxismax>
            <show_work_period>1</show_work_period>
            <show_triggers>1</show_triggers>
            <type>0</type>
            <show_legend>1</show_legend>
            <show_3d>0</show_3d>
            <percent_left>0.0000</percent_left>
            <percent_right>0.0000</percent_right>
            <ymin_type_1>0</ymin_type_1>
            <ymax_type_1>0</ymax_type_1>
            <ymin_item_1>0</ymin_item_1>
            <ymax_item_1>0</ymax_item_1>
            <graph_items>
EOGHEAD
}

print_graph_item(){
  cat <<EOGITEM >> $TPL
                <graph_item>
                    <sortorder>$2</sortorder>
                    <drawtype>0</drawtype>
                    <color>$3</color>
                    <yaxisside>0</yaxisside>
                    <calc_fnc>4</calc_fnc>
                    <type>0</type>
                    <item>
                        <host>Riak</host>
                        <key>Riak.$1</key>
                    </item>
                </graph_item>
EOGITEM
}

print_graph_end(){
  cat <<EOGRAPH >> $TPL
            </graph_items>
        </graph>
EOGRAPH
}

print_end(){
  cat <<EOEND >> $TPL
    </graphs>
</zabbix_export>
EOEND
}

print_graph(){
  local graph_title=$(pp_name $1)
  print_graph_head "$graph_title"
  item_ord=0
  declare -a items=("${!2}")
  for item in ${items[@]}; do
    print_graph_item $item $item_ord ${COLORS[$item_ord]}
    item_ord=$(expr $item_ord + 1)
  done
  print_graph_end
}


print_tpl_head

STATS=($(cat $STAT_LIST))
STATS+=("process_beam.smp")
STATS+=("process_epmd")

for STAT in ${STATS[@]}; do
    print_tpl_item $STAT
done

print_raw_tpl_item "net.tcp.port[127.0.0.1,8098]" "Riak TCP HTTP Interface"
print_raw_tpl_item "net.tcp.port[127.0.0.1,8087]" "Riak TCP PB Interface"

print_post_items

print_trigger "{Riak:net.tcp.port[127.0.0.1,8098].last(0)}=0" "Riak TCP HTTP Interface"
print_trigger "{Riak:net.tcp.port[127.0.0.1,8087].last(0)}=0" "Riak TCP PB Interface"
print_trigger "{Riak:Riak.process_beam.smp.last(0)}=0" "Riak Process Beam.smp"
print_trigger "{Riak:Riak.process_epmd.last(0)}=0" "Riak Process Epmd"

print_post_trigger

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

for graph in $(grep '_gets' $STAT_LIST); do
  title=${graph//_gets/_gets_and_puts}
  items=( $graph ${graph//_gets/_puts} )

  print_graph "$title" items[@]

done

items=( search_index_throughput_count search_query_throughput_count )
print_graph "search-query_index_throughput" items[@]

print_end
