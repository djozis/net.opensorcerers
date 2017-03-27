#!/bin/bash
pwd
./gradlew cgroup check &
CHECK=$!
disown
echo "CHECK is $CHECK"
while kill -0 "$CHECK"; do
    sleep 1
done
