#!/bin/bash

log_file="/tmp/log.out"
IM_HOME=/opt/IBM/IM
BPM_HOME=/opt/IBM/BPM
type_install="AdvancedProcessCenter"

echo "Begin..." | tee -a $log_file

echo "creating [bpmgrp] group"
groupadd bpmgrp

echo "creating [bpmusr] user"
useradd bpmusr -g bpmgrp -p bpmusr

echo "Defining [bpmusr] user password"
echo "bpmusr" | passwd bpmusr --stdin

echo "Defining ulimit parameters"
ulimit -n 65535
echo "*  soft  nofile  65535" >> /etc/security/limits.conf
echo "*  hard  nofile  65535" >> /etc/security/limits.conf

echo "Defining hosts on file '/etc/hosts' for the BPM topology"

echo "192.168.1.1 db2.domain.com" > /etc/hosts
echo "192.168.1.2 bpm.domain.com" >> /etc/hosts
echo "192.168.1.3 ihs.domain.com" >> /etc/hosts

mkdir -p /tmp/bpm_server

echo "Unzip BPM binary v8.5.5" | tee -a $log_file
ls /vagrant/binary_bpm/ | while read line
do
	echo "CMD> [tar xvfz /vagrant/binary_bpm/$line -C /tmp/bpm_server]"
	tar xvfz /vagrant/binary_bpm/$line -C /tmp/bpm_server > /dev/null
done

mkdir -p /opt/IBM
chmod -R 777 /tmp/bpm_server
chown -R bpmusr:bpmgrp /opt/IBM
chmod -R 755 /opt/IBM

REPOSITORY_IM_DIR=/tmp/bpm_server/IM64

echo "Starting installing BPM Installation Manager..." | tee -a $log_file
sudo su - bpmusr -c "$REPOSITORY_IM_DIR/tools/imcl install com.ibm.cic.agent \
        -acceptLicense -installationDirectory $IM_HOME -repositories $REPOSITORY_IM_DIR \
        -showVerboseProgress -log /tmp/silent_im_install.log"

echo "Installing BPM binary." | tee -a $log_file
sudo su - bpmusr -c "$IM_HOME/eclipse/tools/imcl \
    	install com.ibm.bpm.ADV.v85,${type_install} com.ibm.websphere.ND.v85,core.feature,ejbdeploy,thinclient,embeddablecontainer,com.ibm.sdk.6_64bit \
    	-acceptLicense -installationDirectory $BPM_HOME -repositories /tmp/bpm_server/repository/repos_64bit/ \
    	-showVerboseProgress -log /tmp/silent_bpm_install.log"

echo "Configuring the BPM Deployment environment ." | tee -a $log_file
sudo su - bpmusr -c "$BPM_HOME/bin/BPMConfig.sh -create -de /vagrant/deployment_env_bpm85.properties"

echo "END." | tee -a $log_file