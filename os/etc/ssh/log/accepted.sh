grep Accepted /var/log/secure | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort | uniq