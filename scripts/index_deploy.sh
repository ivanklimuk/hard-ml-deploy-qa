#!/bin/bash

if [ $# -ne 8 ]; then
    echo "Please provide all the parameters: SWARM_MANAGER, DOCKER_REGISTRY, DATA_GENERATION, N_CLUSTERS, INDEX_PORT, REDIS_HOST, REDIS_PORT, REDIS_PASSWORD"
    exit 1
fi
SWARM_MANAGER=$1
DOCKER_REGISTRY=$2
DATA_GENERATION=$3
N_CLUSTERS=$4
INDEX_PORT=$5
REDIS_HOST=$6
REDIS_PORT=$7
REDIS_PASSWORD=$8

for ((i=0; i<$N_CLUSTERS; i++))
do
    service_name="index_gen_${DATA_GENERATION}_clust_$i"
    service_port=$(($INDEX_PORT + 100 * $DATA_GENERATION + $i))
    
    echo "Deploying ${service_name}:${service_port}"
    ssh root@$SWARM_MANAGER "docker service create \
        --name $service_name \
        --replicas 1 \
        --reserve-memory 1GB \
        --health-start-period 30s \
        --health-retries 2 \
        -p $service_port:5000 \
        --mount type=bind,source=/var/data,target=/var/data \
        --env SERVICE_NAME=$service_name \
        --env SERVICE_PORT=$service_port \
        --env CLUSTER=$i \
        --env DATA_GENERATION=$DATA_GENERATION \
        --env REDIS_HOST=$REDIS_HOST \
        --env REDIS_PORT=$REDIS_PORT \
        --env REDIS_PASSWORD=$REDIS_PASSWORD \
        $DOCKER_REGISTRY/index" &
done

wait
echo "All indices are deployed"
