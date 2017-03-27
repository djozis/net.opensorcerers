#!/bin/bash
#run with sudo

echo
echo Cleaning up unneeded stuff
echo ... sudo /etc/init.d/mysql stop
sudo /etc/init.d/mysql stop || true
echo ... sudo /etc/init.d/postgresql stop
sudo /etc/init.d/postgresql stop || true
echo ... sudo service postgresql stop
sudo service postgresql stop || true
echo ... sudo service mysql stop
sudo service mysql stop || true
echo ... sudo service memcached stop
sudo service memcached stop || true
echo ... sudo service bootlogd stop
sudo service bootlogd stop || true
echo ... sudo service elasticsearch stop
sudo service elasticsearch stop || true
echo ... sudo service mongodb stop
sudo service mongodb stop || true
echo ... sudo service neo4j stop
sudo service neo4j stop || true
echo ... sudo service cassandra stop
sudo service cassandra stop || true
echo ... sudo service riak stop
sudo service riak stop || true
echo ... sudo service rsync stop
sudo service rsync stop || true
echo ... sudo service x11-common stop
sudo service x11-common stop || true
echo ... ls -al /var/ramfs
ls -al /var/ramfs
echo ... rm -rf /var/ramfs/*
rm -rf /var/ramfs/*

echo
echo Adding swap space
echo ... fallocate -l 4096M $HOME/swapfile
fallocate -l 4096M $HOME/swapfile
echo ... mkswap $HOME/swapfile
mkswap $HOME/swapfile
echo ... sudo swapon $HOME/swapfile
sudo swapon $HOME/swapfile
echo ... sudo sysctl vm.swappiness=100
sudo sysctl vm.swappiness=100
echo ... /bin/sync
/bin/sync
echo ... cat /proc/sys/vm/swappiness
cat /proc/sys/vm/swappiness
echo ... apt-get update -qq
apt-get update -qq
echo ... apt-get install cgroup-bin
apt-get install cgroup-bin -qq
echo
echo Configuring cgroups
cat >> /etc/cgconfig.conf <<- EOF
group memlimit {
    memory {
        memory.limit_in_bytes = 805306368;
    }
}
EOF
echo travis memory memlimit/ >> /etc/cgrules.conf
echo ... service cgconfig restart
service cgconfig restart
echo ... echo $PPID >> /cgroup/memory/memlimit/tasks
echo $PPID >> /cgroup/memory/memlimit/tasks
echo ... top -b -n 1
top -b -n 1
