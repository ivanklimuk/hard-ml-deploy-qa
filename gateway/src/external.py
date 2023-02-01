import requests
import json

from .constants import EMBEDDER_REQUEST_URL, RANKER_REQUEST_URL


def get_embedding(text):
    data = {"instances": [text]}
    res = requests.post(EMBEDDER_REQUEST_URL, json=data)

    return list(map(float, json.loads(res.text)["embeddings"][0]))


def get_ranked(docs):
    data = {"docs": docs}
    res = requests.post(RANKER_REQUEST_URL, json=data)

    return json.loads(res.text)["docs"]


def get_k_closest(search_url, embedding, k):
    data = {"embedding": embedding, "k": k}
    res = requests.post(f"{search_url}/top_k_neighbours", json=data)

    return json.loads(res.text)["docs"]
