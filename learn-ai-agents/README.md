# AI Agents Learning Path

Conceptual and practical topics for understanding how LLMs and AI agents work, from foundations to building agentic systems. Structure follows the curriculum: **Introduction → LLMs → Embeddings → LangChain → API & prompt labs → Vector DBs → RAG → LangGraph → MCP**.

## Prerequisites

- No local setup required for Topic 1 (conceptual).
- Later topics may use API keys (OpenAI, Anthropic, etc.) or local dev environments; each topic will state what you need.

---

## Curriculum (by topic order)

| #   | Topic | Folder | Notes |
| --- | ----- | ------ | ----- |
| 1   | **How LLMs Work in Real Time** | [topic-01-how-llms-work](topic-01-how-llms-work) | Transformers, history, context window, streaming, limitations |
| 2   | **Introduction to AI Agents** | [topic-02-intro-ai-agents](topic-02-intro-ai-agents) | What agents are; goals, tools, and loops |
| 3   | **Embeddings & Vector Representations** | [topic-03-embeddings-vectors](topic-03-embeddings-vectors) | Turning text into vectors; similarity and retrieval |
| 4   | **How LangChain Works** | [topic-04-langchain](topic-04-langchain) | Chains, components, and orchestration |
| 5   | **Practice: Your First AI API Call** | [topic-05-lab-first-api-call](topic-05-lab-first-api-call) | Lab – call an LLM API from code |
| 6   | **Practice: LangChain** | [topic-06-lab-langchain](topic-06-lab-langchain) | Lab – build with LangChain |
| 7   | **Prompt Engineering Techniques** | [topic-07-prompt-engineering](topic-07-prompt-engineering) | System prompts, few-shot, structure, constraints |
| 8   | **Practice: Master Prompt Engineering** | [topic-08-lab-prompt-engineering](topic-08-lab-prompt-engineering) | Lab – apply prompt techniques |
| 9   | **Vector Databases Deep Dive** | [topic-09-vector-databases](topic-09-vector-databases) | Indexing, similarity search, scaling |
| 10  | **Practice: Build Semantic Search Engine** | [topic-10-lab-semantic-search](topic-10-lab-semantic-search) | Lab – semantic search with vectors |
| 11  | **RAG (Retrieval Augmented Generation)** | [topic-11-rag](topic-11-rag) | Retrieve + augment context + generate |
| 12  | **Practice: RAG Implementation** | [topic-12-lab-rag](topic-12-lab-rag) | Lab – end-to-end RAG |
| 13  | **LangGraph for AI Workflows** | [topic-13-langgraph](topic-13-langgraph) | Stateful graphs, nodes, edges, cycles |
| 14  | **Practice: Build Stateful AI Workflow** | [topic-14-lab-stateful-workflow](topic-14-lab-stateful-workflow) | Lab – LangGraph workflow |
| 15  | **Model Context Protocol (MCP)** | [topic-15-mcp](topic-15-mcp) | MCP concepts and integration |
| 16  | **Practice: Advanced MCP Concepts** | [topic-16-lab-mcp-advanced](topic-16-lab-mcp-advanced) | Lab – advanced MCP |

---

## How to Use

1. Work in order: `cd` into each topic folder (e.g. `learn-ai-agents/topic-01-how-llms-work`).
2. Read **INSTRUCTIONS.md** from top to bottom.
3. Do the **Steps** and **Practice** (or lab) before moving to the next topic.

Theory topics (odd numbers 1–15) give concepts; lab topics (5, 6, 8, 10, 12, 14, 16) give hands-on exercises. You can pair them (e.g. Topic 3 + Topic 10 for embeddings and semantic search).
