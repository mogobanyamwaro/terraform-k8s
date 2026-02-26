# Topic 6: Practice – LangChain

## What You'll Learn

- Build a simple LangChain flow (prompt + LLM + optional parser)
- Use LangChain’s model wrappers and prompt templates
- Run a chain and inspect the output
- Optional: add memory or a simple tool

---

## Steps

*(Follow the course lab.)*

### 1. Install and configure

- Install `langchain` and the appropriate chat model package (e.g. `langchain-openai`).
- Set API keys via environment variables; instantiate the LLM through LangChain.

### 2. Build a chain

- Create a **prompt template** with placeholders (e.g. `{input}`).
- Compose: `prompt | llm` (and optionally `| output_parser`).
- Invoke the chain with user input and print the result.

### 3. Extend (optional)

- Add a simple **memory** (e.g. conversation buffer) so the chain has access to prior messages.
- Or add one **tool** and run a minimal agent loop that can call it.

---

## Practice

1. Change the prompt template and see how the model’s behavior changes.
2. If you added memory, send a follow-up that refers to earlier content and confirm the model “remembers”.

---

## Next Topic

**Topic 7: Prompt Engineering Techniques** – system prompts, few-shot, structure, and constraints.
