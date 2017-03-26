#run with sudo
echo "deb https://apt.dockerproject.org/repo ubuntu-precise main" > /etc/apt/sources.list.d/docker.list
service cgconfig start
ls /sys/fs
apt-get update -qq
apt-get install cgroup-bin
cat >> /etc/cgconfig.conf <<- EOF
group memlimit {
    memory {
        memory.limit_in_bytes = 2147483648;
    }
}
EOF
echo travis memory memlimit/ >> /etc/cgrules.conf
service cgconfig start
