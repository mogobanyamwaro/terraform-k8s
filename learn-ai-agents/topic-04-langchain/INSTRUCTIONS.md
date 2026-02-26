# Topic 4: How LangChain Works

## What You'll Learn

- **LangChain** as a framework for LLM applications: components and orchestration
- **Chains** – composing prompts, LLM calls, and post-processing
- **Components**: prompts, models (LLMs/chat), output parsers, memory, tools
- How this connects to agents and RAG

---

## Steps

*(Content to be filled as you follow the course.)*

### 1. What LangChain is

- A library/framework for building applications that use LLMs: prompt management, model calls, chaining, tools, and integrations (vector stores, APIs).
- You compose **components** (prompt templates, LLMs, parsers) into **chains** or **agent** loops.

### 2. Core concepts

- **LCEL** (LangChain Expression Language) – compose runnables with `|` (e.g. `prompt | llm | parser`).
- **Chains** – sequences of steps: e.g. load context → build prompt → call LLM → parse output.
- **Memory** – conversation buffer or summary injected into the chain.
- **Tools** – callable functions the LLM can choose to use (agent pattern).

### 3. How it fits the curriculum

- LangChain gives you a standard way to do “prompt + LLM + parse” and “retrieve + prompt + LLM” (RAG). LangGraph (Topic 13) extends this with explicit state and graphs.

---

## Practice

1. Draw a simple chain: user input → prompt template → LLM → output parser. What does each step do?
2. What is the difference between a “chain” and an “agent” in LangChain?

---

## Next Topic

**Topic 5: Practice – Your First AI API Call** – lab: call an LLM API from code.
