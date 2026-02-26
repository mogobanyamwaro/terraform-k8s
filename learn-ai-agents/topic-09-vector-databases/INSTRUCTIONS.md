# Topic 9: Vector Databases Deep Dive

## What You'll Learn

- What a **vector database** is: store vectors and query by similarity
- **Indexing** – how vectors are stored for fast approximate nearest neighbor (ANN) search
- **Similarity search** – k-NN, distance metrics, and filters
- Scaling and options (embedded vs server; Pinecone, Weaviate, Chroma, pgvector, etc.)

---

## Steps

*(Content to be filled as you follow the course.)*

### 1. Why vector DBs

- Embeddings live in high-dimensional space. Finding “closest” vectors to a query vector is the core operation for semantic search and RAG.
- A **vector database** stores embeddings and supports **similarity search** (e.g. “return top-k vectors closest to this query vector”), often with metadata filters.

### 2. Indexing and search

- **Index** – data structure (e.g. HNSW, IVF) that speeds up approximate nearest neighbor (ANN) search instead of brute-force comparison.
- **Metrics** – cosine similarity, Euclidean (L2), or dot product; choice affects ranking and some index types.
- **Metadata** – filter by attributes (e.g. “only documents from 2024”) while doing vector search.

### 3. Options and trade-offs

- **Embedded** (e.g. Chroma, SQLite + vector) – good for dev and small data.
- **Server** (e.g. Pinecone, Weaviate, Qdrant) – managed, scalable.
- **Postgres** (pgvector) – vector support inside your existing DB.
- Choice depends on scale, latency, and ops.

---

## Practice

1. In one sentence: what is the main operation a vector DB optimizes for?
2. Why might you use “approximate” rather than exact nearest neighbor?

---

## Next Topic

**Topic 10: Practice – Build Semantic Search Engine** – lab: build semantic search with embeddings and a vector store.
