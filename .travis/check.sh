#!/bin/bash
pwd
(./gradlew cgroup check; echo "$?" >> "$HOME/check-result") &
CHECK=$!
disown
echo "CHECK is $CHECK"
while kill -0 "$CHECK"; do
    sleep 1
done
exit $(head -n 1 "$HOME/check-result")
