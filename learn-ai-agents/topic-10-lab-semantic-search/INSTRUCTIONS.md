# Topic 10: Practice – Build Semantic Search Engine

## What You'll Learn

- Embed a small corpus of documents (or sentences)
- Store embeddings in a vector store (e.g. Chroma, in-memory, or cloud)
- Embed a query and run similarity search to get top-k results
- Compare semantic search to keyword search (optional)

---

## Steps

*(Follow the course lab.)*

### 1. Corpus and embeddings

- Choose a small set of documents (e.g. a few paragraphs or a mini FAQ).
- Use an embedding API or model to get a vector for each document (or chunk).
- Store document text and embedding (and optional metadata) for later retrieval.

### 2. Vector store

- Create an index / collection in your chosen vector DB (or in-memory structure).
- Insert all document embeddings (and metadata). Ensure you can query by vector.

### 3. Query

- Take a user question (or search phrase), embed it with the same model.
- Run similarity search: return top-k most similar stored vectors (and their text).
- Display the retrieved passages as “search results”.

### 4. Optional

- Run the same query with a simple keyword match (e.g. grep or string contains). Compare results to semantic search to see when meaning matters more than exact words.

---

## Practice

1. Try a query that uses different words than the document but the same meaning; confirm semantic search still finds it.
2. Change k (e.g. top-3 vs top-10) and observe how recall/precision feel.

---

## Next Topic

**Topic 11: RAG (Retrieval Augmented Generation)** – retrieve + augment context + generate.
