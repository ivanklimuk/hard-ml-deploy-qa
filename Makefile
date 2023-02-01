# Export all environment variables

include configs/vars.env
export $(cat configs/vars.env | xargs) && rails c


######################################### High-level steps #########################################

prepare:
	data
	nodes

build:
	embedder/build 
	embedder/push 
	ranker/build
	ranker/push
	index/build
	index/push
	gateway/build
	gateway/push

deploy:
	embedder/deploy
	ranker/deploy
	index/registry
	index/deploy
	gateway/deploy

update:
	index/update

######################################### Detailed targets #########################################

# Nodes settings
nodes:
	echo "Setup nodes utilities"
	scripts/install_utils.sh ${SWARM_MANAGER}

# Data
data/prepare:
	echo "Building data generation (on local machine)"
	python3 scripts/build_generation.py

data/push:
	echo "Deliver data to swarm nodes"
	scripts/deliver_data.sh ${HOSTS} ${DATA_GENERATION}

data: data/prepare data/push

# Embedder
embedder/build:
	echo "Build embedder image"
	docker build --squash -t ${DOCKER_REGISTRY}/embedder - < docker/Dockerfile.embedder

embedder/push:
	echo "Push embedder image"
	docker push ${DOCKER_REGISTRY}/embedder

embedder/deploy:
	echo "Deploy embedder"
	ssh root@${SWARM_MANAGER} "docker service create --replicas 1 --name embedder -p ${EMBEDDER_PORT}:8501 ${DOCKER_REGISTRY}/embedder"

embedder/stop:
	echo "Not implemented"


# Ranker
ranker/build:
	echo "Build ranker image"
	docker build --squash -t ${DOCKER_REGISTRY}/ranker -f docker/Dockerfile.ranker ranker

ranker/push:
	echo "Push ranker image"
	docker push ${DOCKER_REGISTRY}/ranker

ranker/deploy:
	echo "Deploy ranker"
	ssh root@${SWARM_MANAGER} "docker service create --replicas 1 --name ranker -p ${RANKER_PORT}:5000 ${DOCKER_REGISTRY}/ranker"

ranker/stop:
	echo "Not implemented"


# Indices
index/registry:
	echo "Run redis registry for index discovery"
	ssh root@${REDIS_HOST} "docker run -d -p ${REDIS_PORT}:${REDIS_PORT} docker.io/library/redis:latest /bin/sh -c 'redis-server --requirepass ${REDIS_PASSWORD}'"
	ssh root@${REDIS_HOST} "docker run -d -p 8001:8001 docker.io/redislabs/redisinsight:latest"

index/build:
	echo "Build (empty) index image"
	docker build --squash -t ${DOCKER_REGISTRY}/index -f docker/Dockerfile.index index

index/push:
	echo "Push index image"
	docker push ${DOCKER_REGISTRY}/index

index/deploy:
	echo "Deploy index clusters"
	scripts/index_deploy.sh ${SWARM_MANAGER} ${DOCKER_REGISTRY} ${DATA_GENERATION} ${N_CLUSTERS} ${INDEX_PORT} ${REDIS_HOST} ${REDIS_PORT} ${REDIS_PASSWORD}

index/update:
	echo "Update index clusters with data generation ${DATA_GENERATION}"
	scripts/index_update.sh ${SWARM_MANAGER} ${DOCKER_REGISTRY} ${DATA_GENERATION} ${N_CLUSTERS} ${INDEX_PORT} ${REDIS_HOST} ${REDIS_PORT} ${REDIS_PASSWORD}

index/stop:
	echo "Stop all indices"
	scripts/index_stop.sh ${SWARM_MANAGER} ${REDIS_HOST} ${REDIS_PORT} ${REDIS_PASSWORD}


# Gateway
gateway/build:
	echo "Build gateway image"
	docker build --squash -t ${DOCKER_REGISTRY}/gateway -f docker/Dockerfile.gateway gateway

gateway/push:
	echo "Push gateway image"
	docker push ${DOCKER_REGISTRY}/gateway

gateway/deploy:
	echo "Deploy gateway service"
	ssh root@${SWARM_MANAGER} "docker service create \
		--replicas 2 \
		--replicas-max-per-node 1 \
		--name gateway \
		-p ${GATEWAY_PORT}:5000 \
		--env REDIS_HOST=${REDIS_HOST} \
		--env REDIS_PORT=${REDIS_PORT} \
		--env REDIS_PASSWORD=${REDIS_PASSWORD} \
		--env EMBEDDER_PORT=${EMBEDDER_PORT} \
		--env RANKER_PORT=${RANKER_PORT} \
		${DOCKER_REGISTRY}/gateway"

gateway/stop:
	echo "Not implemented"
