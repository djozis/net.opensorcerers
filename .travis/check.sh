#!/bin/bash
pwd
./gradlew cgroup check &
CHECK=$!
disown
wait $CHECK
