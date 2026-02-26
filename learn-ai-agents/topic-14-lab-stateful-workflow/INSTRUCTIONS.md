# Topic 14: Practice – Build Stateful AI Workflow

## What You'll Learn

- Define a LangGraph workflow: state schema, nodes, and edges
- Implement at least one node that calls an LLM and one that runs a tool (or mock)
- Add conditional edges (e.g. “if tool call then tool node else end”)
- Run the graph and inspect state updates across steps

---

## Steps

*(Follow the course lab.)*

### 1. State and nodes

- Define a **state** type (e.g. messages, last_tool_call, next_action).
- Create nodes: e.g. **agent** (LLM decides next action or final answer), **tools** (execute the chosen tool and return result).
- Each node receives state and returns a state update (e.g. new messages, tool output).

### 2. Graph and edges

- Add nodes to the graph and connect them with edges.
- Use **conditional edges** from the agent node: if the LLM output is a tool call → route to tools node; else → route to end.
- From the tools node, edge back to the agent node so it can “see” the tool result and decide again.

### 3. Run and inspect

- Invoke the graph with an initial state (e.g. user message).
- Run until the graph reaches the end node (or max steps). Print or log state after each step to see the flow.

---

## Practice

1. Add a second tool and ensure the agent can choose between them.
2. Set a maximum number of steps and handle the case when the agent doesn’t finish in time.

---

## Next Topic

**Topic 15: Model Context Protocol (MCP)** – MCP concepts and integration.
