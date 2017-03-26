#!/bin/bash
while true
do
    echo
	top -b -n 1 | head -5 | tail -2 | sed 's/^/    /'
	sleep 10
done
