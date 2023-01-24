include configs/vars.env
export $(cat configs/vars.env | xargs) && rails c

build_embedder:
	docker build -t ${DOCKER_REGISTRY}/embedder -f docker/Dockerfile.embedder .

push_embedder:
	docker push ${DOCKER_REGISTRY}/embedder

run_embedder:
	ssh root@${SWARM_MANAGER_IP} "docker service create --replicas 1 --name embedder -p 8501:8501 ${DOCKER_REGISTRY}/embedder"