#!/bin/bash
while true
do
	top -b -n 1 | head -10
	sleep 10
done
