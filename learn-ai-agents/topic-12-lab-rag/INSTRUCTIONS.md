# Topic 12: Practice – RAG Implementation

## What You'll Learn

- Build a full RAG pipeline: load docs → chunk → embed → store
- Query: embed question → retrieve top-k → build prompt with context → call LLM → return answer
- Optionally add source citations or re-ranking
- Compare answers with vs without retrieval

---

## Steps

*(Follow the course lab.)*

### 1. Ingest

- Load a small document set (e.g. a PDF, markdown, or text files).
- Chunk the text (by paragraph or fixed size with overlap).
- Embed each chunk and store in a vector DB (from Topic 10). Keep mapping from chunk ID to text and source.

### 2. Query path

- Accept a user question. Embed it with the same model.
- Retrieve top-k chunks from the vector store.
- Build a prompt: system instruction + “Context: …” (retrieved chunks) + “Question: …” (user question) + “Answer:”.
- Call the LLM and return the generated answer.

### 3. Polish (optional)

- Include source references in the prompt and ask the model to cite them.
- Or add a re-ranker step between retrieval and prompt building.
- Try the same question without RAG (no context) and compare quality and hallucinations.

---

## Practice

1. Ask a question that’s answered in your docs and one that isn’t; compare how the model behaves.
2. Change k (e.g. 3 vs 7) and chunk size; observe effect on answer quality and token usage.

---

## Next Topic

**Topic 13: LangGraph for AI Workflows** – stateful graphs, nodes, edges, and cycles.
