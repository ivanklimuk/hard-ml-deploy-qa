import redis

from .constants import (
    REDIS_HOST,
    REDIS_PASSWORD,
    REDIS_PORT,
)

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=0,
    password=REDIS_PASSWORD,
)
