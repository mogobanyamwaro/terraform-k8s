# Topic 16: Practice – Advanced MCP Concepts

## What You'll Learn

- Use MCP in practice: configure a client (e.g. Cursor) to talk to an MCP server
- Call MCP tools from an agent or IDE and use MCP resources as context
- Optional: build or extend a simple MCP server that exposes custom tools or resources
- Understand how MCP fits into your AI agent or workflow stack

---

## Steps

*(Follow the course lab.)*

### 1. Client configuration

- Configure your environment (e.g. Cursor) to connect to one or more MCP servers (e.g. filesystem, web fetch, custom).
- Verify the client sees the server’s tools and/or resources (e.g. list tools, read a resource by URI).

### 2. Use tools and resources

- From an agent or the IDE, invoke an MCP tool (e.g. run a command, fetch a URL) and use the result in the next step.
- Request an MCP resource and confirm the model (or your code) receives the content. Observe how this augments context.

### 3. Optional: custom server or tools

- If the course covers it: run a simple MCP server that exposes one custom tool (e.g. “get_weather”) or resource (e.g. “config”).
- Connect your client to it and call the tool or read the resource. See how the same protocol works across different servers.

---

## Practice

1. List the MCP servers you have configured and what tools/resources they expose.
2. Describe one workflow where MCP tools + an LLM would be better than the LLM alone.

---

## End of curriculum

You’ve completed the path from **How LLMs work** → **Agents** → **Embeddings** → **LangChain** → **Prompts** → **Vector DBs** → **RAG** → **LangGraph** → **MCP**. Next: build a full agent project that combines RAG, tools, and (optionally) MCP and LangGraph.
