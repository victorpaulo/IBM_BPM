#!/bin/bash

log_file="/tmp/log.out"
echo "Installing the DB2 UDB Server v10.5" | tee -a $log_file

mkdir -p /tmp/db2_server

useradd bpmadmin -g db2iadm1 -p bpmadmin

echo "Creating user [bpmadmin] which will be used as services account to connect on db2"
echo "bpmadmin" | passwd bpmadmin --stdin

echo "Setting the hosts on file [/etc/hosts] for the topology."

echo "192.168.1.1 db2.domain.com" > /etc/hosts
echo "192.168.1.2 bpm.domain.com" >> /etc/hosts
echo "192.168.1.3 ihs.domain.com" >> /etc/hosts

echo "Unziping the DB2 binaries" | tee -a $log_file
tar xvfz /vagrant/binary_db2/DB2_Svr_10.5.0.3_Linux_x86-64.tar.gz -C /tmp/db2_server > /dev/null

echo "Installing DB2 v10.5 using response file" | tee -a $log_file 
/tmp/db2_server/server/db2setup -r /vagrant/db2ese.rsp | tee -a $log_file 

echo "Installation of DB2 v10.5 finished." | tee -a $log_file

echo "Creating BPM databases"

echo "Creating BPM database [BPMDB]"
sudo su - db2inst1 -c "db2 -tf /vagrant/databases/BPMDB/createDatabase.sql;
					   db2 connect to BPMDB;
					   db2 -tf /vagrant/databases/BPMDB/createSchema_Advanced.sql;
					   db2 -tdGO -vf /vagrant/databases/BPMDB/createProcedure_Advanced.sql;
					   db2 connect reset"

echo "Creating BPM database [CELLDB]"
sudo su - db2inst1 -c " db2 -tf /vagrant/databases/CELLDB/createDatabase.sql;
						db2 connect to CELLDB;
						db2 -tf /vagrant/databases/CELLDB/createSchema_Advanced.sql;
						db2 connect reset"

echo "Creating BPM database [CMNDB]"
sudo su - db2inst1 -c "db2 -tf /vagrant/databases/CMNDB/createDatabase.sql;
						db2 connect to CMNDB;
						db2 -tf /vagrant/databases/CMNDB/createSchema_Advanced.sql;
						db2 -tf /vagrant/databases/CMNDB/createSchema_Messaging.sql;
						db2 connect reset"

echo "Creating BPM database [BPMDB]"
sudo su - db2inst1 -c " db2 -tf /vagrant/databases/PDWDB/createDatabase.sql;
						db2 connect to PDWDB;
						db2 -tf /vagrant/databases/PDWDB/createSchema_Advanced.sql;
						db2 connect reset"
exit 0