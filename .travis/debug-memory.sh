#!/bin/bash
while true
do
	top -b -n 1 | head -5 | tail -2
	sleep 10
done
