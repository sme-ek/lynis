#!/bin/bash

cd /usr/local/src/
dnf install -y git python34
git clone https://github.com/netkiller/firewall.git
cd firewall
bash install.sh

systemctl enable firewall
systemctl start firewall
