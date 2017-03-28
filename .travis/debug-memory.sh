#!/bin/bash
while true
do
    echo
    top -b -n 1 | head -6 | tail -3 | sed 's/^/        /'
    sleep 5
done
