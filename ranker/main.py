from flask import Flask, request

app = Flask(__name__)


def dummy_rank(query, documents):
    return documents[::-1]


@app.route("/rank", methods=["POST"])
def rank():
    query = request.args["query"]
    docs = request.args["documents"]

    res = dummy_rank(query, docs)

    return {"documents": res}
