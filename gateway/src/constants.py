import os

REDIS_HOST = os.environ["REDIS_HOST"]
REDIS_PORT = os.environ["REDIS_PORT"]
REDIS_PASSWORD = os.environ["REDIS_PASSWORD"]

EMBEDDER_PORT = os.getenv("EMBEDDER_PORT", 6001)
RANKER_PORT = os.getenv("RANKER_PORT", 6002)

EMBEDDER_REQUEST_URL = f"embedder:{EMBEDDER_PORT}/v1/models/use-large:predict"
RANKER_REQUEST_URL = f"ranker:{EMBEDDER_PORT}/rank"
