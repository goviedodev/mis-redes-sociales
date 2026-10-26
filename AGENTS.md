# Agent Workflow Router (`hola-ai`)

This project follows the **hola-ai** Extreme Programming workflow: vertical user stories, acceptance criteria, test-first pair programming, and simple design.

## Project Context

Read the product requirements and technical specifications in [PRD.md](./PRD.md) before starting work on `/backlog`, `/story`, or `/pair`.

```text
/backlog  →  /story  →  /pair
  what       what exactly   how
```

## Skill Routing Rules

Before responding to a feature idea, requirement, story refinement, or implementation request, route the task to the appropriate skill and **read its `SKILL.md` file** first:

1. **Backlog (`/backlog`) — Defining *what* to build**
   - **When to route here:** The user shares a new project idea, a broad feature, or asks to break requirements into user stories, or invokes `/backlog`.
   - **Skill instructions:** `/home/goviedo/.gemini/skills/backlog/SKILL.md` (or `~/.claude/skills/backlog/SKILL.md`)
   - **What it does:** Clarifies stack and expensive decisions (one question at a time), then proposes a short backlog of one-line vertical user stories (`As a <actor>, I want <action>, so that <benefit>`).
   - **What it never does:** Never invents requirements, technical stories, acceptance criteria, or estimates.

2. **Story (`/story`) — Defining *what exactly* a single story entails**
   - **When to route here:** The user selects **one** user story from the backlog to refine before coding, or invokes `/story`.
   - **Skill instructions:** `/home/goviedo/.gemini/skills/story/SKILL.md` (or `~/.claude/skills/story/SKILL.md`)
   - **What it does:** Proposes 2–3 `Given / When / Then` acceptance criteria (or proposes splitting the story if >3 are needed) and a mini implementation plan (≤5 bullets), then waits for user approval.
   - **What it never does:** Never writes code or adds abstractions "for the future".

3. **Pair (`/pair`) — Defining *how* to implement via TDD**
   - **When to route here:** A story and its acceptance criteria/mini-plan are approved and the user wants to start coding, continue the next test cycle, or invokes `/pair`.
   - **Skill instructions:** `/home/goviedo/.gemini/skills/pair/SKILL.md` (or `~/.claude/skills/pair/SKILL.md`)
   - **What it does:**
     1. Reviews the refined story and plan against the codebase.
     2. Proposes the **test list** (names and test levels only) and waits for approval.
     3. Executes **1 TDD cycle** at a time (Write 1 test → Run & show Red → Write minimum code → Run & show Green), then stops and reports status waiting for user go-ahead.
   - **What it never does:** Never commits, never edits/skips tests just to make them pass, and never adds unrequested features.

## Core Principles (Always Active)

- **Don't invent:** Missing information gets asked (one question at a time), never assumed.
- **The simplest thing that works:** No premature abstractions or speculative generality.
- **Slice vertically and small:** Stories cross every layer; implementation steps are one test and ~50 lines max.
- **Suggest, don't decide:** Architectural patterns, refactors, and git commits are always the user's call.
- **Explicit checkpoints:** Every phase (`/backlog`, `/story`, `/pair` test list, and each TDD cycle) ends by waiting for explicit user approval.
