import sys
import redis

from .constants import (
    REDIS_HOST,
    REDIS_PASSWORD,
    REDIS_PORT,
    SERVICE_NAME,
    SERVICE_PORT,
)

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=0,
    password=REDIS_PASSWORD,
)


def heartbeat(cluster_center_str):
    print(f"Update the hash key {SERVICE_NAME} in redis")
    redis_client.hset(SERVICE_NAME, "cluster_center", cluster_center_str)
    redis_client.hset(SERVICE_NAME, "port", SERVICE_PORT)
    # expire after (2 x heartbeat + 1) periods
    redis_client.expire(SERVICE_NAME, 61)


def cleanup():
    print(f"Removing the hash key {SERVICE_NAME} from redis", flush=True)
    redis_client.delete(SERVICE_NAME)


def stop_signal_handler(sig, frame):
    cleanup()
    sys.exit(0)
