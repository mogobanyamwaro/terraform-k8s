# Topic 11: RAG (Retrieval Augmented Generation)

## What You'll Learn

- What **RAG** is: retrieve relevant docs → add them to the prompt → generate with the LLM
- **Chunking** – how to split documents for retrieval
- **Retrieval** – similarity search over embeddings (from Topic 9/10)
- **Augmentation** – how to format retrieved chunks in the prompt
- Trade-offs: chunk size, top-k, re-ranking, and hallucination reduction

---

## Steps

*(Content to be filled as you follow the course.)*

### 1. RAG pipeline

- **Retrieve** – given a user question, use embeddings + vector DB to get the top-k most relevant chunks (from your corpus or knowledge base).
- **Augment** – put those chunks (and the question) into the LLM prompt as context.
- **Generate** – the LLM produces an answer conditioned on that context, reducing reliance on internal knowledge and hallucinations when the answer is in the docs.

### 2. Chunking

- Documents are split into **chunks** (e.g. by paragraph, fixed token count, or overlap). Chunk size affects retrieval quality: too small = fragmented; too large = noisy.
- Optional: metadata (source, section) stored with each chunk for citation and filtering.

### 3. Quality and trade-offs

- **Top-k** – more chunks = more context but more noise and cost. Tune k and chunk size.
- **Re-ranking** – optionally use a second model to re-rank retrieved chunks before augmenting.
- **Citation** – include source references in the prompt so the model can cite and so you can verify.

---

## Practice

1. Draw the RAG flow: user question → ? → ? → prompt → LLM → answer. Label each step.
2. Why does RAG often reduce hallucinations for fact-based questions?

---

## Next Topic

**Topic 12: Practice – RAG Implementation** – lab: build an end-to-end RAG pipeline.
