#!/usr/bin/env bash

response="$(echo PING | nc localhost 3310)"
if [[ $response = "PONG" ]]
then
    echo "ClamAV daemon is ready"
    exit 0
fi

echo "ClamAV daemon is NOT ready"
exit 1