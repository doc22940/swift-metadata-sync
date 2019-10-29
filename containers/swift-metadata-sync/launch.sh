#!/bin/bash

set -e

# Make sure all of the .pid files are removed -- services will not start
# otherwise
find /var/lib/ -name *.pid -delete
find /var/run/ -name *.pid -delete

cp -f /swift-metadata-sync/containers/swift-metadata-sync/proxy-server.conf /etc/swift

# Copied from the docker swift container. Unfortunately, there is no way to
# plugin an additional invocation to start swift-s3-sync, so we had to do this.
/usr/sbin/service rsyslog start
/usr/sbin/service rsync start
/usr/sbin/service memcached start
# set up storage
mkdir -p /swift/nodes/1 /swift/nodes/2 /swift/nodes/3 /swift/nodes/4

for i in `seq 1 4`; do
    if [ ! -e "/srv/$i" ]; then
        ln -s /swift/nodes/$i /srv/$i
    fi
done
mkdir -p /srv/1/node/sdb1 /srv/2/node/sdb2 /srv/3/node/sdb3 /srv/4/node/sdb4 \
    /var/run/swift
/usr/bin/sudo /bin/chown -R swift:swift /swift/nodes /etc/swift /srv/1 /srv/2 \
    /srv/3 /srv/4 /var/run/swift
/usr/bin/sudo -u swift /swift/bin/remakerings

/usr/bin/sudo -u swift /swift/bin/startmain

/usr/bin/sudo -u elastic /bin/bash /elasticsearch-${ES_VERSION}/bin/elasticsearch \
    2>&1 > /var/log/elasticsearch.log &

/usr/bin/sudo -u elastic /bin/bash /elasticsearch-${OLD_ES_VERSION}/bin/elasticsearch \
    2>&1 > /var/log/old-elasticsearch.log

/usr/local/bin/supervisord -n -c /etc/supervisord.conf
