#run with sudo
echo ... cgcreate
cgcreate
echo ... service cgconfig start
service cgconfig start
echo ... apt-get update -qq
apt-get update -qq
echo ... apt-get install cgroup-bin
apt-get install cgroup-bin
echo ... 
cat >> /etc/cgconfig.conf <<- EOF
group memlimit {
    memory {
        memory.limit_in_bytes = 2147483648;
    }
}
EOF
echo travis memory memlimit/ >> /etc/cgrules.conf
service cgconfig start
