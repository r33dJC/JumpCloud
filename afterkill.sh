#!/bin/bash
curl -X POST -d 'shutdown' http://127.0.0.1:8088/hash &
curl -X POST -d '{"password":"angrymonkey"}' http://127.0.0.1:8088/hash &
