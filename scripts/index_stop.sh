#!/bin/bash

if [ $# -ne 4 ]; then
    echo "Please provide all the parameters: SWARM_MANAGER, REDIS_HOST, REDIS_PORT, REDIS_PASSWORD"
    exit 1
fi
SWARM_MANAGER=$1
REDIS_HOST=$2
REDIS_PORT=$3
REDIS_PASSWORD=$4

services=$(ssh root@${SWARM_MANAGER} "docker service ls --format '{{.Name}}' | grep '^index_gen_'")
for service_name in $services; do
  echo "Stop and remove service $service"
  ssh root@$SWARM_MANAGER "redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD del $service_name"
  ssh root@$SWARM_MANAGER "docker service rm $service_name"
done