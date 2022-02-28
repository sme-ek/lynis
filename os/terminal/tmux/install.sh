#!/bin/bash
if [ -z $( egrep "CentOS|Redhat" /etc/issue) ]; then
	echo 'Only for Redhat or CentOS'
	exit
fi

dnf install tmux -y