import sys
import redis
import time

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


def heartbeat(cluster_center_str):
    print(f"Update the hash key {SERVICE_URL} in redis")
    redis_client.hset(SERVICE_URL, "cluster_center", cluster_center_str)
    # expire after (2 x heartbeat + 1) periods
    redis_client.expire(SERVICE_URL, 61)


def cleanup():
    print(f"Removing the hash key {SERVICE_URL} from redis", flush=True)
    redis_client.delete(SERVICE_URL)


def stop_signal_handler(sig, frame):
    cleanup()
    time.sleep(60)
    sys.exit(0)
