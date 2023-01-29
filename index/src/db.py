import sys
import redis

from .constants import (
    REDIS_HOST,
    REDIS_PASSWORD,
    REDIS_PORT,
    SERVICE_NAME,
    SERVICE_PORT,
)

SERVICE_URL = f"{SERVICE_NAME}:{SERVICE_PORT}"

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=0,
    password=REDIS_PASSWORD,
)


def register_service(cluster_center_str):
    redis_client.hset(SERVICE_URL, "cluster_center", cluster_center_str)


def first_register_service(cluster_center_str):
    print(f"Register service {SERVICE_URL}", flush=True)
    redis_client.hset(SERVICE_URL, "cluster_center", cluster_center_str)

    # make the data about the service expired after (2 x heartbeat + 1) periods
    redis_client.expire(SERVICE_URL, 61)


def deregister_service():
    print(f"Removing the hash key {SERVICE_URL} from redis", flush=True)
    redis_client.delete(SERVICE_URL)


def stop_signal_handler(sig, frame):
    deregister_service()
    sys.exit(0)
