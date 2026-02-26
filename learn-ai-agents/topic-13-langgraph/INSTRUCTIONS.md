# Topic 13: LangGraph for AI Workflows

## What You'll Learn

- **LangGraph** – graphs of nodes and edges for stateful, multi-step AI workflows
- **State** – shared state object that flows between nodes
- **Nodes** – units of work (e.g. call LLM, call tool, conditional logic)
- **Edges** – conditional or fixed transitions; cycles for agent loops
- How this compares to simple chains and when to use it

---

## Steps

*(Content to be filled as you follow the course.)*

### 1. Why LangGraph

- **Chains** run in a fixed sequence. **Agents** need loops: decide → act → observe → decide again. LangGraph models this as a **graph**: nodes are steps, edges define transitions, and **state** is passed along.
- You get explicit control over flow (branching, loops, human-in-the-loop) and can inspect or persist state.

### 2. Core concepts

- **State** – a schema (e.g. messages, tool_results, next_step) that each node reads and updates.
- **Nodes** – functions that take state and return state updates (e.g. “call LLM”, “run tool”, “check if done”).
- **Edges** – from one node to another; can be **conditional** (e.g. “if tool call then tools node else end”).
- **Cycles** – the graph can loop (e.g. agent → tool → agent) until a stop condition.

### 3. When to use it

- Use LangGraph when you need **multi-step reasoning**, **tool loops**, **branching**, or **persistent state** across steps. Use simple chains when a linear prompt → LLM → parse flow is enough.

---

## Practice

1. Draw a minimal agent graph: start → LLM node → (if tool) tool node → back to LLM; (if end) end.
2. What is the main difference between a LangChain chain and a LangGraph workflow?

---

## Next Topic

**Topic 14: Practice – Build Stateful AI Workflow** – lab: implement a workflow with LangGraph.
