#!/bin/bash

set -m

# start clam service
clamd &

#clamconf

while sleep 60; do
  ps aux | grep clamd | grep -q -v grep
  PROCESS_1_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 ]; then
    echo "clamd exited."
    dmesg | tail -30
    exit 1
  fi
done
