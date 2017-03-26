#run with sudo

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
