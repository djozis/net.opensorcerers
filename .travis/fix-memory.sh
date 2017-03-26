sudo apt-get install libcgroup
cat >> /etc/cgconfig.conf <<- EOF
group memlimit {
    memory {
        memory.limit_in_bytes = 2147483648;
    }
}
EOF
sudo echo travis memory memlimit/ >> /etc/cgrules.conf
sudo service cgconfig start
