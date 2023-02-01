import math


def dot_product(a, b):
    return sum(map(lambda x, y: x * y, a, b))


def cosine_similarity(a, b):
    return dot_product(a, b) / (
        math.sqrt(dot_product(a, a)) * math.sqrt(dot_product(b, b))
    )
