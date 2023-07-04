#!/usr/bin/env bash

clamd &

end=$((SECONDS+120))
while [ $SECONDS -lt $end ]
do
    response="$(echo PING | nc localhost 3310)"
    if [[ $response = "PONG" ]]
    then
        echo "clamd is ready"
        echo VERSION | nc localhost 3310
        break
    else
        echo "clamd is NOT ready yet in $SECONDS sec"
    fi
    sleep 1
done

# Exit if clamd not ready
if [[ $response != "PONG" ]]
then
    echo "clamd did not start within time"
    exit 1
fi


test_virus_found () {
    local scan_result="$(echo SCAN $1 | nc localhost 3310)"
    echo "Scan result: $scan_result"
    if [[ $scan_result == "$1: Win.Test.EICAR_HDB-1 FOUND" ]]
    then
        echo "Test malware signature detected in $1, which is expected."
    else
        echo "Failed to find the expected test malware signature in $1."
        exit 1
    fi
}

# Test whether malware gets detected
test_virus_found "/home/yolt/eicar.txt"
test_virus_found "/home/yolt/eicar.zip"
