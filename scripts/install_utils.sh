#!/bin/bash

if [ -z "$1" ]
then
    echo "Please provide the SWARM_MANAGER as first argument"
    exit 1
fi
SWARM_MANAGER=$1

# Check if redis-cli is installed and install it
if ! ssh root@$SWARM_MANAGER "[ -x \"$(command -v redis-cli)\" ]"; then
    echo "redis-cli is not installed. Installing now..."
    ssh root@$SWARM_MANAGER "apt-get update && apt-get install redis-tools -y"
fi