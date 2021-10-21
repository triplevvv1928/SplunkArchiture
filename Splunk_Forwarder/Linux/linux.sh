#!/bin/sh  
# This script shows how to deploy the Splunk universal forwarder
# to many remote hosts via ssh and common Unix commands.
# For "real" use, this script needs ERROR DETECTION AND LOGGING!!
# --Variables that you must set -----
# Set User
  SPLUNK_RUN_USER="splunk"

# Populate this file with a list of hosts that this script should install to,
# with one host per line. This must be specified in the form that should
# be used for the ssh login, ie. username@host
#
# Example file contents:
# splunkuser@10.20.13.4
# splunkker@10.20.13.5
  HOSTS_FILE="uf_hosts/uf_hosts.conf"

# This should be a WGET command that was *carefully* copied from splunk.com!!
# Sign into splunk.com and go to the download page, then look for the wget
# link near the top of the page (once you have selected your platform)
# copy and paste your wget command between the ""
  WGET_CMD="wget -O splunkforwarder-7.3.1-bd63e13aa157-Linux-x86_64.tgz 'https://d7wz6hmoaavd0.cloudfront.net/products/universalforwarder/releases/7.3.1/linux/splunkforwarder-7.3.1-bd63e13aa157-Linux-x86_64.tgz'"
# Set the install file name to the name of the file that wget downloads
# (the second argument to wget)
  INSTALL_FILE="splunkforwarder-7..1-bd63e13aa157-Linux-x86_64.tgz"

# Indexer Server
  INDEXER_SERVER_1="192.168.0.38:9997"
  INDEXER_SERVER_2="192.168.0.47:9997"
  
# Set the new Splunk admin password
  PASSWORD="khunglong123"

REMOTE_SCRIPT_DEPLOY="
  cd /opt
  sudo $WGET_CMD
  sudo tar xvzf $INSTALL_FILE -C /opt
  sudo rm -rf $INSTALL_FILE
  sudo useradd $SPLUNK_RUN_USER
  sudo chown -R $SPLUNK_RUN_USER:$SPLUNK_RUN_USER /opt/splunkforwarder
  su -c 'echo \"[user_info]
USERNAME = admin
PASSWORD = $PASSWORD\" > /opt/splunkforwarder/etc/system/local/user-seed.conf'
  sudo /opt/splunkforwarder/bin/splunk start --accept-license
  sudo /opt/splunkforwarder/bin/splunk enable boot-start
  sudo /opt/splunkforwarder/bin/splunk add monitor /var/log -index main
  su -c 'echo \"[tcpout]
defaultGroup=indexer1,indexer2
[tcpout:indexer1]
server=$INDEXER_SERVER_1
[tcpout:indexer2]
server=$INDEXER_SERVER_2\" > /opt/splunkforwarder/etc/system/local/outputs.conf'
  sudo firewall-cmd --zone=public --permanent --add-port=8000/tcp
  sudo firewall-cmd --zone=public --permanent --add-port=5514/udp
  sudo firewall-cmd --zone=public --permanent --add-port=9997/tcp
  sudo firewall-cmd --zone=public --permanent --add-port=9997/udp
  sudo firewall-cmd --zone=public --permanent --add-port=8089/tcp
  sudo firewall-cmd --zone=public --permanent --add-port=8089/udp
  sudo firewall-cmd --reload
  exit
 "

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

#===============================================================================================
  echo "In 5 seconds, will run the following script on each remote host:"
  echo
  echo "===================="
  echo "$REMOTE_SCRIPT_DEPLOY"
  echo "===================="
  echo 
  sleep 5
  echo "Reading host logins from $HOSTS_FILE"
  echo
  echo "Starting."
  for DST in `cat "$DIR/$HOSTS_FILE"`; do
    if [ -z "$DST" ]; then
      continue;
    fi
    echo "---------------------------"
    echo "Installing to $DST"
    echo "Initial UF deployment"
    sudo ssh -t "$DST" "$REMOTE_SCRIPT_DEPLOY"
  done  
  echo "---------------------------"
  echo "Done"