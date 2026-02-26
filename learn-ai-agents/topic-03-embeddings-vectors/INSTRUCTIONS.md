# Topic 3: Embeddings & Vector Representations

## What You'll Learn

- What **embeddings** are: dense vectors that represent meaning
- How to get embeddings from text (embedding models / APIs)
- **Similarity** – why “similar meaning” ≈ “close in vector space”
- Why this matters for **semantic search** and **RAG**

---

## Steps

*(Content to be filled as you follow the course.)*

### 1. From text to vectors

- **Embedding** = a fixed-size list of numbers (vector) that represents the meaning of a piece of text.
- You get embeddings by calling an **embedding model** (or API) on a string; it returns a vector (e.g. 768 or 1536 dimensions).
- Same or similar texts → similar vectors; different meanings → vectors farther apart.

### 2. Similarity and distance

- **Cosine similarity** or **Euclidean distance** between two vectors measures how “alike” two texts are.
- Use this to find “the passage most similar to my question” in a corpus → basis of semantic search and RAG retrieval.

### 3. Role in the stack

- Embeddings feed **vector databases** (Topic 9) and **RAG** (Topic 11). You embed documents at index time and the query at query time, then retrieve by similarity.

---

## Practice

1. In one sentence: why do we use embeddings instead of raw text for “find similar documents”?
2. What does “embedding dimension” (e.g. 1536) mean?

---

## Next Topic

**Topic 4: How LangChain Works** – chains, components, and orchestration for LLM apps.
