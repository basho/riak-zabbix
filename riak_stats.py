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
  file.write('%s riak.%s %s %s\n' % ( hostname, zkey, time.time(), data[zkey]) )

file.close()

output = runcmd("zabbix_sender -v -T -c %s -i %s" % ( config_file, stats_file )
print output
