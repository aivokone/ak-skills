---
name: codebase-guide
description: "Generate a beginner-friendly Markdown guide explaining a codebase. Produces a single Markdown file covering purpose, tech stack, architecture, data flow, key files, and how to run."
disable-model-invocation: true
---

# Codebase Guide

Produce a comprehensive, beginner-friendly Markdown guide that explains a code
repository to someone who has never seen it. The guide covers purpose, tech
stack, architecture, data flow, key files, and how to run the project. Every
technical term is defined on first use.

## Workflow

Three phases, in order. Do not start writing until Phase 3.

1. **Discovery** — gather raw data about the repository
2. **Analysis** — build a mental model from the data
3. **Writing** — produce the output document

---

## Phase 1: Discovery

Systematically explore the repository. Gather information in each category
below. Adapt to the project — not every category applies.

### Project Identity

- **Package manifests**: `package.json`, `Cargo.toml`, `pyproject.toml`,
  `setup.py`, `go.mod`, `composer.json`, `Gemfile`, `*.csproj`, `pom.xml`,
  `build.gradle`
- **Documentation**: `README.md`, `README.rst`, `CHANGELOG`, `ARCHITECTURE.md`,
  `docs/`
- **CI/CD**: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`
- **Containerisation**: `Dockerfile`, `docker-compose.yml`

### Project Structure

- Top-level directory listing (1–2 levels deep)
- Identify: source directories, test directories, config, build output, docs
- Detect monorepo patterns: workspaces, `packages/`, `apps/`, `libs/`

### Entry Points and Configuration

- Look for main/index/app/server files in the source root
- Build and run scripts from the manifest (npm scripts, Makefile targets, etc.)
- Environment config: `.env.example`, `config/`, settings files

### Dependencies and Stack

- Framework detection from manifests and import statements
- Database/storage: docker-compose services, ORM config, migration files,
  schema files (`.prisma`, `*.sql`, `models.*`)
- External service integrations: API clients, SDK imports

### Tests and API Surface

- Test directory structure and framework
- Public API: route definitions, exported modules, CLI commands, OpenAPI specs
- Estimate: are there tests? (presence, not coverage percentage)

### Discovery Scope

Scale discovery effort to project size:

| Size | Files | Approach |
|------|-------|----------|
| Small | <50 | Scan everything |
| Medium | 50–500 | Focus on src/, config, entry points |
| Large | 500+ | Sample representative modules, focus on architecture boundaries |

After discovery, **read the most important files**: main entry points, core
modules, config, and at least one test file.

Do not read: generated files, lock file contents, vendor directories, minified
bundles.

---

## Phase 2: Analysis

Before writing, answer these questions internally. Do not produce output yet.

### Purpose

- What does this project do in one sentence?
- Who is the intended user?
- What problem does it solve?

### Architecture

- What is the high-level structure? (monolith, microservices, library, CLI,
  full-stack app, pipeline, serverless)
- What are the main boundaries or layers?
- How does data flow through the system? (request lifecycle, pipeline stages,
  event flow)

### Key Abstractions

- What are the 3–7 most important types, classes, or modules?
- What patterns are used? (MVC, pub/sub, middleware, hooks, plugins)
- What are the important interfaces or contracts between modules?

### Developer Experience

- How does someone set up and run this locally?
- How are tests run?
- What is the build/deploy pipeline?
- Are there non-obvious prerequisites?

### Rough Sizing

- Tiny (<500 LOC), small, medium, or large (>50k LOC)?
- This determines output depth (see writing rules).

---

## Phase 3: Writing

Produce **one Markdown file** following the section structure in
`references/output-template.md`. Apply the guidelines from
`references/writing-rules.md`.

Read both reference files before starting this phase.

### Output Location

- Default path: `docs/CODEBASE_GUIDE.md`. Create the `docs/` directory if it
  does not exist.
- If the user specifies a path, use that instead. Create parent directories as
  needed.
- **Always confirm the output path with the user before writing.**
- If a file already exists at the path, ask before overwriting.

### Required Sections

Follow the template order. Omit sections that do not apply:

1. Document Header
2. What Is This
3. Tech Stack
4. Project Map
5. Architecture
6. Data Flow
7. Key Files Explained
8. Key Concepts
9. How to Run
10. Testing
11. Where to Go Next
12. Glossary (only if the project has domain-specific terminology)

### Target Length

- Small project: 100–200 lines
- Medium project: 200–400 lines
- Large project: 300–500 lines

---

## Output Defaults

- No emoji in headings
- Use Mermaid syntax for diagrams (renders on GitHub, GitLab, most doc viewers)
- Use annotated ASCII trees for directory structure
- Copy-pasteable commands in code blocks with language annotations
- Define every technical term on first use

---

## Reference Loading

Load only the reference you need for the current phase:

- Output section specs → `references/output-template.md`
- Tone and writing guidelines → `references/writing-rules.md`

Read these before starting Phase 3. Do not load them during discovery or
analysis.

---

## Scope Limits

This skill produces one static explanatory document. It does **not**:

- Generate API documentation (use dedicated tools like typedoc, pydoc, swagger)
- Create step-by-step tutorials or how-to guides
- Maintain or auto-update the document over time
- Cover deployment runbooks or operational procedures

For monorepos: explain the top-level structure and one representative package
in depth. List other packages with one-sentence descriptions.
