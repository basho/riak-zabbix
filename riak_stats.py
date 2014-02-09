#! /usr/bin/env python
try:
    from configobj import ConfigObj
    detect_hostname= False
except:
    detect_hostname = True
import optparse
import sys
import traceback
import urllib2
import socket
import struct
import time
from subprocess import Popen, PIPE, STDOUT
import os
import platform

riak_metrics = ("converge_delay_last","converge_delay_max","converge_delay_mean","converge_delay_min","coord_redirs_total","dropped_vnode_requests_total","executing_mappers","gossip_received","handoff_timeouts","ignored_gossip_total","index_fsm_active","index_fsm_create","index_fsm_create_error","list_fsm_active","list_fsm_create","list_fsm_create_error","mem_allocated","mem_total","memory_atom","memory_atom_used","memory_binary","memory_code","memory_ets","memory_processes","memory_processes_used","memory_system","memory_total","node_get_fsm_active","node_get_fsm_active_60s","node_get_fsm_in_rate","node_get_fsm_objsize_100","node_get_fsm_objsize_95","node_get_fsm_objsize_99","node_get_fsm_objsize_mean","node_get_fsm_objsize_median","node_get_fsm_out_rate","node_get_fsm_rejected","node_get_fsm_rejected_60s","node_get_fsm_rejected_total","node_get_fsm_siblings_100","node_get_fsm_siblings_95","node_get_fsm_siblings_99","node_get_fsm_siblings_mean","node_get_fsm_siblings_median","node_get_fsm_time_100","node_get_fsm_time_95","node_get_fsm_time_99","node_get_fsm_time_mean","node_get_fsm_time_median","node_gets","node_gets_total","node_put_fsm_active","node_put_fsm_active_60s","node_put_fsm_in_rate","node_put_fsm_out_rate","node_put_fsm_rejected","node_put_fsm_rejected_60s","node_put_fsm_rejected_total","node_put_fsm_time_100","node_put_fsm_time_95","node_put_fsm_time_99","node_put_fsm_time_mean","node_put_fsm_time_median","node_puts","node_puts_total","pbc_active","pbc_connects","pbc_connects_total","pipeline_active","pipeline_create_count","pipeline_create_error_count","pipeline_create_error_one","pipeline_create_one","postcommit_fail","precommit_fail","read_repairs","read_repairs_total","rebalance_delay_last","rebalance_delay_max","rebalance_delay_mean","rebalance_delay_min","rejected_handoffs","riak_kv_vnodeq_max","riak_kv_vnodeq_mean","riak_kv_vnodeq_median","riak_kv_vnodeq_min","riak_kv_vnodeq_total","riak_kv_vnodes_running","riak_pipe_vnodeq_max","riak_pipe_vnodeq_mean","riak_pipe_vnodeq_median","riak_pipe_vnodeq_min","riak_pipe_vnodeq_total","riak_pipe_vnodes_running","sys_global_heaps_size","sys_process_count","vnode_gets","vnode_gets_total","vnode_index_deletes","vnode_index_deletes_postings","vnode_index_deletes_postings_total","vnode_index_deletes_total","vnode_index_reads","vnode_index_reads_total","vnode_index_refreshes","vnode_index_refreshes_total","vnode_index_writes","vnode_index_writes_postings","vnode_index_writes_postings_total","vnode_index_writes_total","vnode_puts","vnode_puts_total")

if sys.version_info >= (2, 6):
    import json
else:
    import simplejson as json


def get_options():
    """ command-line options """

    usage = "usage: %prog [options]"
    OptionParser = optparse.OptionParser
    parser = OptionParser(usage)

    parser.add_option("-u", "--url", action="store", type="string", \
            dest="url", default="http://localhost:8098/stats", help="Riak Stats URL")

    options, args = parser.parse_args()

    return options, args


def build_dict(json):

    raw_data = urllib2.urlopen(options.url).read()
    data = json.loads(raw_data)
    return data

def get_json(options):
    raw_data = urllib2.urlopen(options.url).read()
    return json

def runcmd(cmd):
    p = Popen(cmd, shell=True, stdin=PIPE, stdout=PIPE, stderr=STDOUT, close_fds=True)
    output = p.stdout.read()
    output.strip()
    return output


(options, args) = get_options()

json = get_json(options)
data = build_dict(json)

stats_file = '/tmp/riak_stats.txt'
config_file = '/etc/zabbix/zabbix_agentd.conf'
file=open(stats_file, 'w')

if detect_hostname == False:
    config = ConfigObj(config_file)
    hostname = config.get('Hostname')
    if hostname == None:
      hostname = platform.node()
else:
    hostname = platform.node()

for zkey in data.keys():
  if zkey in riak_metrics:
    file.write('%s riak.%s %s %s\n' % ( hostname, zkey, time.time(), data[zkey]) )

file.close()

output = runcmd("zabbix_sender -v -T -c %s -i %s" % ( config_file, stats_file ))
print output

