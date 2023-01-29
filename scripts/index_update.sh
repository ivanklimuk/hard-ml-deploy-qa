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

# Iterate over all existing index services
for service_name in $(ssh root@$SWARM_MANAGER "docker service ls --format '{{.Name}}' | grep '^index_gen_'"); do
  clust_value=$(echo $service_name | awk -F '_' '{print $5}')
  new_service_name="index_gen_${DATA_GENERATION}_clust_$clust_value"
  new_service_port=$(($INDEX_PORT + 100 * $DATA_GENERATION + $clust_value))
  
  # Check if the new service aready exists and skip it
  service_exists=$(ssh root@$SWARM_MANAGER "docker service ls --format '{{.Name}}' | grep '^$new_service_name$'")
  if [ ! -z "$service_exists" ]; then
    echo "Service $new_service_name already exists, skipping..."
    continue
  fi
  
  echo "Creating new service $new_service_name..."
  ssh root@$SWARM_MANAGER "docker service create \
    --name $new_service_name \
    --reserve-memory 1GB \
    --health-start-period 30s \
    --health-retries 2 \
    -p $new_service_port:5000 \
    --mount type=bind,source=/var/data,target=/var/data \
    --env SERVICE_NAME=$new_service_name \
    --env SERVICE_PORT=$new_service_port \
    --env CLUSTER=$clust_value \
    --env DATA_GENERATION=$DATA_GENERATION \
    --env REDIS_HOST=$REDIS_HOST \
    --env REDIS_PORT=$REDIS_PORT \
    --env REDIS_PASSWORD=$REDIS_PASSWORD \
    $DOCKER_REGISTRY/index" &

  echo "Check if the new service is ready and available..."
  retries=10
  while true; do
    sleep 30

    service_ready=$(ssh root@$SWARM_MANAGER "redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD exists $new_service_name:$new_service_port")
    if [ $service_ready -eq 1 ]; then
      echo "The new service $new_service_name is ready and available"
      break
    fi
    
    if [ $retries -eq 0 ]; then
      echo "Failed to start the new service $new_service_name after $retries retries, shutting it down..."
      docker service rm $new_service_name
      exit 1
    fi
    
    retries=$((retries-1))
    echo "The new service is not yet ready, $retries retries left..."
  done

  echo "Stopping the previous service $service_name..."
  ssh root@$SWARM_MANAGER "docker service rm $service_name"
done
