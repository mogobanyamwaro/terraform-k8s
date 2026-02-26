# Topic 15: Model Context Protocol (MCP)

## What You'll Learn

- What **MCP (Model Context Protocol)** is: a standard way for AI applications to use external tools and data sources
- **Servers** – expose resources (tools, data) to **clients** (e.g. Cursor, other agents)
- **Tools and resources** – how MCP exposes callable tools and readable context
- How MCP fits into agents and IDEs (e.g. Cursor’s MCP integration)

---

## Steps

*(Content to be filled as you follow the course.)*

### 1. What MCP is

- **Model Context Protocol** is an open protocol so that AI models (or agents) can discover and use **tools** and **resources** provided by **MCP servers**.
- A **client** (e.g. an IDE or agent framework) connects to one or more **servers**; each server advertises tools (e.g. “run command”, “read file”) and/or resources (e.g. docs, data). The model gets context and can invoke tools through the client.

### 2. Key concepts

- **MCP server** – process that implements the protocol: lists tools/resources, handles tool calls, returns content.
- **Tools** – named, parameterized actions the model can request (e.g. search, run code, fetch URL).
- **Resources** – named data the model can read (e.g. file contents, API responses). Resources have URIs and optional metadata.
- **Client** – talks to servers and presents tools/resources to the model (or user). Cursor and other editors can act as MCP clients.

### 3. Why it matters

- MCP gives a **standard** way to plug in databases, APIs, files, and custom tools so any MCP-aware agent or IDE can use them without custom glue per integration.
- You’ll use MCP when building or configuring agents that need rich context and tools (e.g. Cursor rules, Nx, browser, etc.).

---

## Practice

1. In one sentence: what does an MCP server provide to an MCP client?
2. Name one “tool” and one “resource” that would be useful for a coding assistant.

---

## Next Topic

**Topic 16: Practice – Advanced MCP Concepts** – lab: advanced MCP usage and custom servers or tools.
