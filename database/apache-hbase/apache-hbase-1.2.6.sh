cd /usr/local/src
wget http://mirrors.hust.edu.cn/apache/hbase/stable/hbase-1.2.6-bin.tar.gz

tar zxf hbase-1.2.6-bin.tar.gz
cp hbase-1.2.6/conf/hbase-site.xml{,.original}
mv hbase-1.2.6 /srv/apache-hbase-1.2.6
rm -f /srv/apache-hbase
ln -s /srv/apache-hbase-1.2.6 /srv/apache-hbase

chown hadoop:hadoop -R /srv/apache-hbase-1.2.6
