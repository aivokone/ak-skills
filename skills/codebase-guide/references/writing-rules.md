# Writing Rules

Guidelines for writing the codebase guide output. Read before starting Phase 3.

---

## Tone and Language

- Write for someone who has never seen the codebase and may be new to the
  stack.
- Use "you" to address the reader: "When you run this command, you'll see..."
- Conversational but precise — not academic, not sloppy.
- No unexplained jargon. Define terms on first use, inline:
  "a JWT (JSON Web Token — a signed permission slip the server gives the
  client)"
- Prefer active voice: "The router maps URLs to handlers" not "URLs are
  mapped to handlers by the router."
- No emoji in headings. Minimal emoji elsewhere.
- Be direct. Avoid hedging ("might", "could possibly", "it seems like").

---

## Explaining Code

- Tie explanations to specific files and line ranges.
- Explain WHAT the code does and WHY, not just WHERE it is.
- Use inline code formatting for file paths, function names, and short
  snippets.
- For longer references, use fenced code blocks with language annotation.
- Show the relevant 3–10 lines, not entire files.
- Prefer the "interesting" part of a file over boilerplate.
- Describe what the code does **before** showing it — never show a code block
  without context.

---

## Diagrams

- Use Mermaid syntax for all diagrams (renders on GitHub, GitLab, most doc
  platforms).
- Architecture: `graph TD` or `graph LR` for component relationships.
- Data flow: `sequenceDiagram` for request lifecycle.
- Keep simple: 5–12 nodes for architecture, 4–8 participants for sequences.
- Every node must have a human-readable label, not a variable name or
  abbreviation.
- If a diagram would exceed 12 nodes, decompose into subsystem diagrams.
- Do not create diagrams that merely restate the directory tree — diagrams
  should show runtime relationships, data flow, or component interactions.

---

## Scaling Depth

Adjust detail level based on project complexity:

| Size | Files | Approach |
|------|-------|----------|
| Small | <50 | Explain nearly every file. Full directory tree. Short document. |
| Medium | 50–500 | Focus on architecture boundaries. One module deep-dive. 2–3 diagrams. |
| Large | 500+ | Top-level architecture. One module deep-dive. Mention others by name. 3+ diagrams. |

### By project type

- **Libraries**: focus on the public API surface first, then explain internals.
- **Applications**: focus on the request lifecycle, then supporting modules.
- **CLIs**: focus on command structure and argument parsing, then core logic.
- **Monorepos**: explain top-level structure and shared infrastructure. Pick one
  representative package for deep-dive. List others with one-sentence
  descriptions.

### What to scale down

A 50-line CLI script does not need:
- A sequence diagram
- A glossary
- A "Key Concepts" section
- Separate "Architecture" and "Data Flow" sections — merge them

A 100k-line monorepo does not need:
- Every file listed in the project map
- Every module explained in depth — pick the most important

---

## What to Omit

- Generated files (build output, lock file contents, compiled assets)
- Standard boilerplate identical across all projects in this stack
  (e.g., default tsconfig, standard Cargo.toml metadata)
- Deeply nested implementation details that don't affect understanding
- Historical context unless it explains a current design decision
- Personal opinions about code quality
- TODOs or future plans — the document explains what IS, not what should be
- Sensitive information (flag if found: API keys, passwords, tokens in code)

---

## Common Pitfalls

Avoid these when writing the guide:

- **Listing without explaining**: A directory tree is not architecture. Every
  listed file needs a role description.
- **Explaining the tool instead of the project**: The reader can look up
  React.js — explain how THIS project uses React.
- **Writing a tutorial**: This document orients and explains. It does not teach
  step-by-step how to build features.
- **Over-documenting small projects**: A 50-line CLI does not need a sequence
  diagram and a glossary.
- **Under-documenting complex interactions**: If understanding requires tracing
  5 files, draw the diagram.
- **Using project-internal shorthand**: Terms like "the processor" or "the
  engine" need definition — the reader does not know what they refer to yet.
