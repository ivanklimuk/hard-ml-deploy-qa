import numpy as np
import faiss

import os
import shutil
import json
from tqdm.auto import tqdm

DATA_GENERATION = os.getenv("DATA_GENERATION", "1")
RAW_PATH = "./data.misc/raw"
OUTPUT_PATH = f"./data.misc/{DATA_GENERATION}"

os.makedirs(OUTPUT_PATH, exist_ok=True)
print("Copy cluster centers")
shutil.copy(
    f"{RAW_PATH}/{DATA_GENERATION}/clusters_centers_use_dg1.pkl",
    f"{OUTPUT_PATH}/clusters_centers.pkl",
)

with open(f"{RAW_PATH}/{DATA_GENERATION}/clusters_use_dg1.json") as f:
    clusters_dict = json.load(f)

use_embeddings = np.load(
    f"{RAW_PATH}/{DATA_GENERATION}/use_embeddings_dg1.pkl", allow_pickle=True
)

for cluster_id, cluser_docs in clusters_dict.items():
    print(f"{cluster_id = }")
    idx_to_doc = {}
    doc_emebeddings = []

    print("Collect embeddings")
    for idx, doc in enumerate(tqdm(cluser_docs)):
        idx_to_doc[idx] = doc
        doc_emebeddings.append(use_embeddings[doc])

    print("Build search index")
    search_index = faiss.index_factory(512, "L2norm,HNSW32", faiss.METRIC_INNER_PRODUCT)
    search_index.add(np.vstack(doc_emebeddings))

    print("Save results")
    CLUSTER_PATH = OUTPUT_PATH + f"/{cluster_id}/"
    os.makedirs(CLUSTER_PATH, exist_ok=True)

    faiss.write_index(search_index, CLUSTER_PATH + "search_index.faiss")
    with open(CLUSTER_PATH + "idx_to_doc.json", "w") as f:
        json.dump(idx_to_doc, f)
