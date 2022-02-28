#!/bin/bash
ORACLE_BASE=/opt/oracle
ORACLE_PASSWORD="oracle"

function ECHO(){
	echo "===================="
	echo $1
	echo "===================="
}

dnf install gcc gcc-c++ glibc-devel libstdc++ libstdc++-devel libaio-devel libaio-devel \ 
elfutils-libelf-devel unixODBC unixODBC-devel compat-libstdc++-33 pdksh sysstat

groupadd oinstall
groupadd dba
useradd -m -g oinstall -G dba oracle
echo "oracle:$ORACLE_PASSWORD" | chpasswd
ECHO $"$(id oracle)"

mkdir -p $ORACLE_BASE
chown -R oracle:oinstall $ORACLE_BASE
chmod -R 775 $ORACLE_BASE

#ECHO "/opt/oracle"

cat >> /etc/sysctl.conf <<EOF
fs.aio-max-nr = 3145728
fs.file-max = 6815744
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.shmmni = 4096
kernel.sem = 250 32000 100 142
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF
#ECHO $"$(/sbin/sysctl -p)"

cat >> /etc/security/limits.conf <<EOF
oracle soft nproc 2048
oracle hard nproc 16384
oracle soft nofile 2048
oracle hard nofile 65536
EOF
#ECHO $"$(grep oracle /etc/security/limits.conf)"

cat >> /home/oracle/.bash_profile <<\EOF
export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=orcl.example.com
export ORACLE_UNQNAME=orcl
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1
export ORACLE_SID=orcl
export ORACLE_HOME_LISTNER=$ORACLE_HOME
export PATH=/usr/sbin:$PATH
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8"
EOF

cat >> /home/oracle/.bashrc <<\EOF
alias sysdba='sqlplus "/ as sysdba"'
EOF

#cat >> /etc/oraInst.loc <<EOF
#inventory_loc=$ORACLE_BASE/oraInventory
#inst_group=oinstall
#EOF
#chmod 664 /etc/oraInst.loc

cat >> /etc/hosts <<\EOF
127.0.0.1	oral.example.com
EOF
