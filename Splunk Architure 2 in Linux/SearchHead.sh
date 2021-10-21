#!/bin/sh  
# This script shows how to deploy the Splunk universal forwarder
# to many remote hosts via ssh and common Unix commands.
# For "real" use, this script needs ERROR DETECTION AND LOGGING!!
# --Variables that you must set -----
# Set user
  SPLUNK_RUN_USER="splunk"

# Populate this file with a list of hosts that this script should install to,
# with one host per line. This must be specified in the form that should
# be used for the ssh login, ie. username@host
#
# Example file contents:
# splunkuser@10.20.13.4
# splunkker@10.20.13.5
  HOSTS_FILE="uf_hosts/uf_hosts_SearchHead.conf"

# This should be a WGET command that was *carefully* copied from splunk.com!!
# Sign into splunk.com and go to the download page, then look for the wget
# link near the top of the page (once you have selected your platform)
# copy and paste your wget command between the ""
  WGET_CMD="wget -O splunk-7.3.9-39a78bf1bc5b-Linux-x86_64.tgz 'https://download.splunk.com/products/splunk/releases/7.3.9/linux/splunk-7.3.9-39a78bf1bc5b-Linux-x86_64.tgz'"
# Set the install file name to the name of the file that wget downloads
# (the second argument to wget)
  INSTALL_FILE="splunk-7.3.9-39a78bf1bc5b-Linux-x86_64.tgz"
# Master Cluster Ip
  MASTER_CLUSTER_IP="192.168.0.42:8089"
# Set the new Splunk admin password
  PASSWORD="khunglong123"

REMOTE_SCRIPT_DEPLOY="
  cd /opt
  sudo $WGET_CMD
  sudo tar xvzf $INSTALL_FILE -C /opt
  sudo rm -rf $INSTALL_FILE
  sudo useradd $SPLUNK_RUN_USER
  sudo chown -R $SPLUNK_RUN_USER:$SPLUNK_RUN_USER /opt/splunk 
  su -c 'echo \"[user_info]
USERNAME = admin
PASSWORD = $PASSWORD\" > /opt/splunk/etc/system/local/user-seed.conf'
  su -c 'echo \"[clustering]
master_uri = https://$MASTER_CLUSTER_IP
mode = searchhead
pass4SymmKey = $PASSWORD\" > /opt/splunk/etc/system/local/server.conf'
  sudo /opt/splunk/bin/splunk start --accept-license
  sudo /opt/splunk/bin/splunk enable boot-start
  sudo /opt/splunk/bin/splunk enable listen 9997 -auth admin:$PASSWORD
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
    sudo ssh -t "$DST" "$REMOTE_SCRIPT_DEPLOY"
  done  
  echo "---------------------------"
  echo "Done"