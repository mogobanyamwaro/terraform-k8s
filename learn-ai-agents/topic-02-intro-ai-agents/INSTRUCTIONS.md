# Topic 2: Introduction to AI Agents

## What You'll Learn

- What an **AI agent** is and how it differs from a single LLM call
- **Goals**, **tools**, and **loops**: perceive → decide → act
- Why agents matter for real-world tasks (search, code, APIs, persistence)
- How this sets up LangChain, RAG, and LangGraph

---

## Steps

*(Content to be filled as you follow the course. Key ideas: agent = system that uses LLM + tools + memory in a loop to achieve a goal.)*

### 1. Define an agent

- An **agent** is a system that uses an LLM to **decide** what to do next, then **acts** (e.g. call a tool, search, run code) and **observes** the result, repeating until the goal is met or a stop condition is reached.
- Contrast: one-shot LLM call = single prompt → single response. Agent = multi-step loop with tools and state.

### 2. Core components

- **Goal** – User intent or task (e.g. “book a flight”, “summarize this doc and email it”).
- **Tools** – Functions the agent can call (search, calculator, API, file read/write).
- **Memory / state** – What the agent remembers (conversation history, intermediate results, plan).
- **Loop** – Observe state → LLM decides next action (or answer) → execute tool if any → update state → repeat.

### 3. Why agents matter

- Many tasks need **multiple steps**, **external data**, or **tools**. Agents combine LLM reasoning with tool use and persistence.
- Later topics (LangChain, RAG, LangGraph, MCP) give you the building blocks to implement agents.

---

## Practice

1. List three tasks that are “one LLM call” vs “need an agent loop”.
2. For a “book a flight” agent, name at least two tools it would need.

---

## Next Topic

**Topic 3: Embeddings & Vector Representations** – how text becomes vectors for similarity and retrieval.
