#!/bin/bash

groupadd -g 80 www
adduser -o --home /www --uid 80 --gid 80 -c "Web Application" www

dnf install -y curl-devel libmcrypt-devel mhash-devel gd-devel libjpeg-devel libpng-devel libXpm-devel libxml2-devel libxslt-devel openssl-devel recode-devel 
#dnf install openldap-devel net-snmp-devel

dnf localinstall -y http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
dnf install mysql-community-devel -y

dnf install -y http://dnf.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-1.noarch.rpm
dnf install -y postgresql94-devel

cd /usr/local/src/
wget http://cn2.php.net/distributions/php-5.5.23.tar.gz

if [ -s php-5.5.23.tar.gz ]; then

tar zxf php-5.5.23.tar.gz
cd php-5.5.23

./configure --prefix=/srv/php-5.5.23 \
--with-config-file-path=/srv/php-5.5.23/etc \
--with-config-file-scan-dir=/srv/php-5.5.23/etc/conf.d \
--enable-fpm \
--enable-opcache \
--with-fpm-user=www \
--with-fpm-group=www \
--with-pear \
--with-curl \
--with-gd \
--with-jpeg-dir \
--with-png-dir \
--with-freetype-dir \
--with-zlib-dir \
--with-iconv \
--with-mcrypt \
--with-mhash \
--with-pdo-mysql \
--with-mysql \
--with-mysql-sock=/var/lib/mysql/mysql.sock \
--with-mysqli=/usr/bin/mysql_config \
--with-pdo-pgsql=/usr/pgsql-9.4 \
--with-openssl \
--with-xsl \
--with-recode \
--with-tsrm-pthreads \
--enable-sockets \
--enable-soap \
--enable-mbstring \
--enable-exif \
--enable-gd-native-ttf \
--enable-zip \
--enable-xml \
--enable-bcmath \
--enable-calendar \
--enable-shmop \
--enable-dba \
--enable-wddx \
--enable-sysvsem \
--enable-sysvshm \
--enable-sysvmsg \
--enable-pcntl \
--disable-debug

fi

[[ $? -ne 0 ]] && echo "Error: configure" &&  exit $?

make -j12

[[ $? -ne 0 ]] && echo "Error: make" &&  exit $?

if [ $(id -u) != "0" ]; then
    sudo make install
else
	make install
fi

[[ $? -ne 0 ]] && echo "Error: make install" &&  exit $?

strip /srv/php-5.5.23/bin/php
strip /srv/php-5.5.23/bin/php-cgi

mkdir -p /srv/php-5.5.23/etc/conf.d
mkdir -p /srv/php-5.5.23/etc/fpm.d
cp /srv/php-5.5.23/etc/pear.conf{,.original}
cp php.ini-* /srv/php-5.5.23/etc/
cp /srv/php-5.5.23/etc/php.ini-production /srv/php-5.5.23/etc/php.ini
cp /srv/php-5.5.23/etc/php.ini-development /srv/php-5.5.23/etc/php-cli.ini
cp /srv/php-5.5.23/etc/php-fpm.conf.default /srv/php-5.5.23/etc/php-fpm.conf

#\cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
yes|cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
chkconfig --add php-fpm
chkconfig php-fpm on

rm -f /srv/php
ln -s /srv/php-5.5.23/ /srv/php

vim /srv/php-5.5.23/etc/php-fpm.conf <<end > /dev/null 2>&1
:25,25s/;//
:32,32s/;//
:93,93s/;rlimit_files = 1024/rlimit_files = 65536/
:230,230s/pm.max_children = 5/pm.max_children = 2048/
:235,235s/pm.start_servers = 2/pm.start_servers = 8/
:240,240s/pm.min_spare_servers = 1/pm.min_spare_servers = 8/
:245,245s/pm.max_spare_servers = 3/pm.max_spare_servers = 16/
:256,256s/;pm.max_requests = 500/pm.max_requests = 1024/
:355,355s/;pm.status_path/pm.status_path/
:367,367s/;ping.path/ping.path/
:449,449s/;request_terminate_timeout = 0/request_terminate_timeout = 30s/
:453,453s/;rlimit_files = 1024/rlimit_files = 40960/
:wq
end

#:15,15s/;//

vim /srv/php-5.5.23/etc/php.ini <<EOF > /dev/null 2>&1
:298,298s$;open_basedir =$open_basedir = /www/:/tmp/:/var/tmp/:/srv/php-5.5.23/lib/php/:/srv/php-5.5.23/bin/$
:303,303s/disable_functions =/disable_functions = ini_set,set_time_limit,set_include_path,passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket/
:363,363s/expose_php = On/expose_php = Off/
:393,393s/memory_limit = 128M/memory_limit = 32M/
:755,755s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/
:910,910s:;date.timezone =:date.timezone = Asia/Hong_Kong:
:1387,1387s:;session.save_path = "/tmp":session.save_path = "/dev/shm":
:1413,1413s/session.name = PHPSESSID/session.name = JSESSIONID/
:wq
EOF

#s/max_execution_time = 30/max_execution_time = 300/g
#:706,706s!;include_path = ".:/php/includes"!include_path = ".:/srv/php-5.5.23/lib/php:/srv/php-5.5.23/share"!
#:728,728s!; extension_dir = "./"!extension_dir = "./:/srv/php-5.5.23/lib/php/extensions:/srv/php-5.5.23/lib/php/extensions/no-debug-non-zts-20121212"!
#:804,804s/upload_max_filesize = 2M/upload_max_filesize = 3M/

vim /srv/php-5.5.23/etc/php-cli.ini <<EOF > /dev/null 2>&1
:393,393s/memory_limit = 128M/memory_limit = 4G/
:572,572s/;error_log/error_log/
:910,910s:;date.timezone =:date.timezone = Asia/Hong_Kong:
:wq
EOF

cat >> ~/.bashrc <<EOF

alias php='php -c /srv/php/etc/php-cli.ini'
PATH=$PATH:/srv/php/bin:
EOF

cat >> /etc/man.config <<EOF
MANPATH  /srv/php/man/
EOF

cat >> /etc/profile.d/php.sh <<'EOF'
export PATH=/srv/php/bin:$PATH
EOF

source /etc/profile.d/php.sh
