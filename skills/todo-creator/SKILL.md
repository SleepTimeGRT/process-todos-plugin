---
name: todo-creator
description: Use this skill whenever the user wants to turn a feature idea, requirement, or description into structured todo/task markdown files for process-todos. Trigger on any request to create, generate, or write todos/tasks (todo 만들어줘, 투두 생성, create todos, make todo tickets), break down or decompose a feature into work items (작업 분해해줘, 기능 정리해줘, break this into tasks, decompose this feature), plan implementation steps or build a task list (태스크 나눠줘, 작업 목록 만들어, plan this feature, set up work items), or convert a description into actionable tickets (이거 todo로 만들어줘, feature breakdown 해줘, turn this into tasks). Also trigger when the user describes a feature and implies they want it organized into implementable units, even without saying "todo" — if they say "이 기능 정리해서 나눠줘" or "help me plan how to build this", that counts. This skill creates todo files; it does NOT execute or process them.
required_skills:
  - superpowers:brainstorming
  - dx:handoff
  - superpowers:test-driven-development
  - feature-dev:feature-dev
---

# Todo Creator

Turns a natural language feature description into well-structured todo ticket files that the `process-todos` system can pick up and execute automatically.

The goal is to save the user from having to manually write todo markdown files. They describe what they want in plain language, and this skill produces ready-to-process todo tickets — each with a clear title, context, and a checklist of concrete implementation steps.

## How It Works

### Step 1 — Load Configuration

Read `.process-todos.json` from the project root. If it doesn't exist, use defaults:
- `todo_path`: `docs/todos`
- `type_check_command`: `npm run check-types`
- `branch_prefix`: `todo/`

### Step 2 — Understand the Request via Brainstorming

The user gives a natural language description of what they want built. This could be anything from a one-liner ("add dark mode") to a full product spec.

Before generating todos, invoke `/superpowers:brainstorming` to deeply explore the problem space. Brainstorming is valuable here because feature decomposition has many valid approaches, and exploring alternatives early leads to better-structured todos. The brainstorming session should cover:
- What are the major components of this feature?
- What are the dependencies between components?
- What existing code will be affected?
- Are there architectural decisions that should be made upfront?

**Making decisions during brainstorming:** When brainstorming presents multiple approaches and a choice needs to be made, spawn a `todo-analyst` agent (`Agent(subagent_type="process-todos:todo-analyst", prompt=<decision question with options>)`). The analyst examines the codebase — existing patterns, conventions, dependencies — and returns a grounded recommendation. Use the analyst's recommendation to move brainstorming forward without blocking on the user for every decision.

**If brainstorming skill is unavailable** (e.g., running in a subagent without installed skills): perform the decomposition analysis yourself. Cover the same ground — major components, dependencies, affected code, architectural decisions — by reading the codebase directly. The structure matters more than having the brainstorming skill specifically.

After brainstorming, build further context:
1. Read the project's `CLAUDE.md` (if it exists) to understand conventions, tech stack, and project structure
2. If the request references existing code, read those files to understand the current state
3. If the request is vague, ask one round of clarifying questions — but keep it focused. Don't over-interview. Better to make reasonable assumptions and note them than to block on questions.

### Step 3 — Break Down into Todos

Use the brainstorming output to decide how to split the work:

**Splitting by concern, not by size:**
- Split along **natural boundaries** — backend vs frontend, data model vs business logic, core feature vs integrations
- If there are ordering dependencies (e.g., "create the DB schema before the API endpoints") → **number the filenames** to ensure correct processing order
- Each todo should represent a **coherent unit of work** — something that makes sense on its own and produces a meaningful, testable result

**Prefer finer layer separation for multi-concern features.** When a feature spans data → API → UI, prefer 3 todos over 2. In particular:
- **Separate the data layer** (DB schema, migrations, seed data) from the API routes that consume it. Schema changes are a foundation — getting them right first prevents rework downstream.
- **Separate client state from UI** for complex interactive features. Stores, hooks, and WebSocket connections are testable independently of the rendering layer. A dedicated state-management todo lets the worker establish the data flow before any UI is built.
- This finer split produces more independently reviewable PRs and reduces merge conflicts in parallel processing.

**Don't fear large todos.** The worker agents support handoff (`/dx:handoff`) — when a worker approaches its context limit, it writes a HANDOFF.md documenting progress and decisions, and a fresh worker picks up where it left off. This means a todo with 10+ checklist items is perfectly fine if the items are logically cohesive. Splitting tightly coupled work across separate todos creates more problems (merge conflicts, duplicated context) than letting one worker handle it with handoffs.

**When to split vs keep together:**
- Split when concerns are **independent** — they can be implemented in separate git worktrees without stepping on each other's changes
- Keep together when items are **tightly coupled** — they modify the same files, share new types/interfaces, or one item's implementation depends on decisions made in another

### Step 4 — Write the Todo Files

Create markdown files in `{todo_path}/`. Each file follows this format:

```markdown
# <Clear, action-oriented title>

<1-2 sentences of context explaining WHY this work matters and HOW it fits into the bigger picture. This helps the worker agent make good decisions when implementation details aren't specified.>

- [ ] <Concrete, implementable step>
- [ ] <Another step>
- [ ] <...>
```

**File naming convention:**
- Use kebab-case: `add-user-auth.md`
- When order matters, prefix with numbers: `01-create-db-schema.md`, `02-add-api-endpoints.md`
- Keep names descriptive but concise (under 40 characters)

**Writing good checklist items:**
Each item should be something a developer (or an AI agent) can pick up and implement without needing additional clarification. Think of them as mini-specifications.

Good: `- [ ] Create POST /api/auth/login endpoint that accepts { email, password } and returns a JWT token`
Bad: `- [ ] Handle authentication`

Good: `- [ ] Add error boundary component in src/components/ErrorBoundary.tsx that catches render errors and shows a retry button`
Bad: `- [ ] Add error handling`

Include file paths when you know where the code should go. The worker benefits enormously from knowing the target location upfront.

**Beyond code — what else to include in checklist items:**

- **Test specifications**: Include at least one item per todo that names the test file path and describes 2+ specific test scenarios. Example: `- [ ] Write tests in src/lib/__tests__/reset-token.test.ts: (a) creates valid token, (b) returns null for expired token, (c) returns null for already-used token`
- **Type definitions**: When the feature introduces new data shapes, include an item to define TypeScript types/interfaces or Zod validation schemas. Example: `- [ ] Define WsServerEvent and WsClientEvent discriminated unions in src/lib/chat/ws-types.ts`
- **Component prop interfaces**: For UI todos, specify what props each component accepts. Example: `- [ ] AvatarUpload accepts { currentAvatarUrl: string | null, onSuccess: (newUrl: string) => void }`
- **Error handling mapping**: When backend returns specific error codes, include how the frontend should display them. Example: `- [ ] On 401, show "현재 비밀번호가 올바르지 않습니다." next to the current-password input`
- **Design assumptions**: State the assumptions in the context paragraph so the worker knows the boundaries. Example: "File uploads stored locally in public/uploads/ — no external storage service assumed."

### Step 5 — Present and Confirm

After writing the files, show the user a summary:

```
## Created Todos

1. **01-create-db-schema.md** (4 items) — Set up the database tables for user auth
2. **02-add-api-endpoints.md** (5 items) — Implement login/signup/logout API routes
3. **03-add-auth-ui.md** (6 items) — Build the login form and auth state management

Files saved to: {todo_path}/
Run `/process-todos` to start processing.
```

If the user wants changes, edit the files accordingly. Once confirmed, they're ready to go.

## Edge Cases

**User gives a very large request** (e.g., "build me a full e-commerce platform"):
Don't shy away from big plans. The worker's handoff mechanism handles context limits gracefully, so even ambitious features can be tackled. Focus on splitting by concern (data layer, API, UI, integrations) rather than artificially limiting scope. If the request is truly enormous (10+ todos), present the full plan but ask the user to confirm before writing all files.

**User gives a tiny request** (e.g., "fix the typo in the header"):
Still create a todo file — the process-todos system expects markdown files. But keep it minimal: a title and 1-2 checklist items.

**Existing todos in the directory:**
Check for existing `.md` files in `{todo_path}/`. If there are any, mention them and ask whether the new todos should be added alongside or replace them. If using numbered prefixes, continue from the highest existing number.

**Ambiguous requirements:**
Make a reasonable assumption, document it in the todo's context paragraph, and move on. For example: "Assuming JWT-based auth since the project already uses jsonwebtoken (see package.json)." The worker can adjust during implementation if needed.

## What Makes a Good Todo

The best todos share these qualities:
- **Self-contained context**: The worker shouldn't need to ask follow-up questions — include enough background that a fresh agent can start immediately
- **Documented assumptions**: Context paragraphs explicitly state what's assumed about the tech stack, storage, auth strategy, etc. — so the worker knows the design boundaries upfront
- **Specific file paths**: When you know where code should go, say so
- **Type-aware**: New data shapes get TypeScript type definitions or Zod schemas specified as checklist items
- **Testable**: Each todo includes at least one item with a test file path and specific test scenarios — not just "add tests"
- **Clear acceptance criteria**: Each checklist item implies a "done when..." condition
- **Coherent scope**: Items in one todo should be logically related, even if there are many of them — handoff handles length
- **Ordered dependencies**: If todo B depends on todo A's output, the filenames should reflect this
