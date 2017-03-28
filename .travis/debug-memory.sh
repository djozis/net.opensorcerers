#!/bin/bash
while true
do
    echo
    top -b -n 1 | head -5 | tail -4 | sed 's/^/        /'
    sleep 5
done
