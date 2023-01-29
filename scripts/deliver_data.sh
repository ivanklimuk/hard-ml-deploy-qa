#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Please provide all the parameters: HOSTS, DATA_GENERATION"
    exit 1
fi
HOSTS=$1
DATA_GENERATION=$2

for host in $(echo $HOSTS | tr ";" "\n")
do
    (
        echo "Deliver data to $host"
        ssh root@$host "mkdir -p /var/data/$DATA_GENERATION/"
        rsync -avz -e "ssh" ./data.misc/$DATA_GENERATION/ root@$host:/var/data/$DATA_GENERATION/
    ) &
done

wait
echo "Data generation $DATA_GENERATION delivered to all nodes"