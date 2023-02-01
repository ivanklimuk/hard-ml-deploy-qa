"""
NB! 

This version of the gateway service is simplified for the sake of simplicity.
Potential improvements:

- Make the service asynchronous - we make a lot of requests to external sources, which makes the service I/O bound
- If one index fails to return any result - retry and/or check the next closest one
"""

from flask import Flask, request, jsonify

from src.utils import cosine_similarity
from src.external import get_embedding, get_k_closest, get_ranked
from src.db import redis_client


def get_top_docs(query_embedding, top_k):
    """
    Search for similar documents in the corresponding index cluster
    """
    index_hosts = redis_client.keys("index_*")

    max_sim = -float("inf")
    closest_index_url = None

    for index_host in index_hosts:
        values = redis_client.hgetall(index_host)
        cluster_center = list(map(float, values["cluster_center"].split(",")))
        index_port = values["port"]

        sim_to_query = cosine_similarity(cluster_center, query_embedding)
        if sim_to_query > max_sim:
            max_sim = sim_to_query
            closest_index_url = f"{index_host}:{index_port}"

    if max_sim < 0.2:
        # if none of the clusters is close enough return empty list
        return []

    top_docs = get_k_closest(
        search_url=closest_index_url, embedding=query_embedding, k=top_k
    )

    return top_docs


app = Flask(__name__)


@app.route("/search_similar", methods=["POST"])
def search_handler():
    text = request.json["text"]
    top_k = request.json["top_k"]

    query_embedding = get_embedding(text)

    top_docs = get_top_docs(query_embedding, top_k)

    if len(top_docs) == 0:
        return jsonify(documents=[])

    top_docs_ranked = get_ranked(top_docs)

    return jsonify(documents=top_docs_ranked)