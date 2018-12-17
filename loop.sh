#!/bin/bash
COUNTER=0
while [ $COUNTER -lt 100 ]; do
    curl -X POST -d '{"password":"angrymonkey"}' http://127.0.0.1:8088/hash &
    let COUNTER=COUNTER+1
done
