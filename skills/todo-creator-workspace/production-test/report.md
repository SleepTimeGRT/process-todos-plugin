# Production Test Report: todo-creator skill on process-todos-plugin

## Test Parameters

- **Repo**: `process-todos-plugin` (the plugin's own codebase)
- **Prompt**: "process-todos 플러그인에 설정 validation 기능을 추가해줘. .process-todos.json 파일을 읽을 때 스키마 검증하고, 잘못된 설정이면 에러 메시지를 보여주는 거야. JSON Schema나 Zod 쓸 수 있을 것 같아."
- **Date**: 2026-03-03
- **Output directory**: `skills/todo-creator-workspace/production-test/outputs/`

---

## Step-by-Step Workflow Execution

### Step 1 — Load Configuration

- `.process-todos.json` does not exist in this repo.
- Defaults applied: `todo_path: docs/todos`, `type_check_command: npm run check-types`, `branch_prefix: todo/`
- **Observation**: This step worked cleanly. The fallback behavior is well-specified.

### Step 2 — Understand the Request (Brainstorming + Analyst)

**Brainstorming fallback used**: The `/superpowers:brainstorming` skill was not available (running in a standalone agent context). Per SKILL.md instructions, the decomposition analysis was performed directly.

**todo-analyst simulation**: The analyst agent was simulated by following its exact procedure from `agents/todo-analyst.md`. The decision question was: "JSON Schema (lightweight, runtime-only) vs Zod (TypeScript-native, type inference) for config validation."

**Analyst findings (following the 4-step procedure)**:

1. **Parse the decision**: JSON Schema = zero runtime dependency, works as a standalone document. Zod = TypeScript-native, infers types, but requires a TS runtime.

2. **Read project context**: Examined directory structure, `.gitignore`, `plugin.json`, all skill/agent markdown files.

3. **Find existing patterns** (CRITICAL FINDING): This project has **no JavaScript or TypeScript source files**. No `package.json`, no `tsconfig.json`, no `.ts`/`.js` files anywhere. The entire plugin is pure markdown instructions and JSON configuration. Config reading is done by Claude Code's `Read` tool interpreting JSON text, not by a Node.js program.

4. **Assessment**:
   - **Zod is not viable**: There is no TypeScript runtime in this project. Zod requires `import { z } from 'zod'` in executable code. This project has no executable code.
   - **JSON Schema is the clear choice**: It can serve as a standalone, machine-readable schema document. Validation happens either (a) in the markdown instructions (Claude Code checks fields after reading JSON) or (b) via `ajv-cli` as an optional tool.
   - **Confidence: high** — codebase has zero TS/JS files, making this an obvious forced choice.

**Analyst recommendation output** (simulated):
```
## Recommendation
JSON Schema. The project has no TypeScript/JavaScript runtime — it is a pure
markdown/JSON plugin. Zod requires a TS runtime that does not exist here.

**Confidence:** high
- The codebase has zero .ts/.js files. This is not a stylistic preference — Zod
  is physically impossible to use without adding a runtime.

## Evidence
- `Glob("**/*.ts")` and `Glob("**/*.js")`: no files found
- `Glob("**/package.json")`: no files found
- `Glob("**/tsconfig.json")`: no files found
- Config is read via Claude Code's `Read` tool in SKILL.md instructions, not
  programmatic JSON.parse()

## Trade-offs
- Zod rejected: requires a TypeScript runtime that this project does not have.
  Adding one purely for config validation would be architecturally inappropriate
  for a markdown-instruction-based plugin.
```

### Step 3 — Break Down into Todos

Applied the SKILL.md guidance on splitting by concern:

1. **01-define-config-schema.md** — Data layer: the schema definition itself and its tests. This is the foundation other work depends on.
2. **02-add-validation-to-skill-instructions.md** — Integration layer: modifying the actual skill markdown files to enforce validation. Depends on the schema existing.
3. **03-error-ux-and-edge-cases.md** — UX layer: error message polish, i18n, edge case handling. Depends on the validation logic being in place.

The "finer layer separation" guidance from SKILL.md was applied: schema definition is separated from validation logic, which is separated from UX polish.

### Step 4 — Write Todo Files

3 files written to `skills/todo-creator-workspace/production-test/outputs/`.

### Step 5 — Summary

```
## Created Todos

1. **01-define-config-schema.md** (5 items) — Define the JSON Schema for .process-todos.json and validate it with tests
2. **02-add-validation-to-skill-instructions.md** (5 items) — Update SKILL.md files to enforce validation when reading config
3. **03-error-ux-and-edge-cases.md** (7 items) — Handle edge cases and polish error messages with Korean/English support

Files saved to: skills/todo-creator-workspace/production-test/outputs/
```

---

## Assessment: todo-analyst Invocation

**Could it be invoked?** No. The `Agent()` subagent spawning mechanism is not available in this execution context. The SKILL.md says `Agent(subagent_type="process-todos:todo-analyst", prompt=...)` but this requires the Claude Code plugin runtime's agent spawning capability, which is not available when running the skill manually in a conversation.

**Workaround used**: Followed the analyst's `agents/todo-analyst.md` procedure manually (4-step analysis). This produced a high-quality recommendation because the procedure is well-documented and self-contained.

**Impact of the analyst's analysis**: The analyst finding was *mission-critical*. Without examining the codebase, the natural assumption would be "use Zod since SKILL.md mentions it in examples and the user suggested it." The analyst revealed that Zod is physically impossible here because there is no TypeScript runtime. This fundamentally changed the approach from "which library?" to "there is no runtime — validation must be instruction-based or schema-document-based."

---

## Comparison: Production Test vs Synthetic Evals

| Dimension | Synthetic Evals (iteration-2) | Production Test |
|---|---|---|
| **Codebase context** | None — evals assume a generic Next.js/Prisma project | Full — actual project with real constraints |
| **Analyst used** | Never (HANDOFF.md notes "not yet exercised in evals") | Simulated with real codebase evidence |
| **Technology assumptions** | Default to common stack (React, Prisma, Zod) | Discovered actual stack (pure markdown, no runtime) |
| **File paths in checklist items** | Generic (`src/lib/...`, `prisma/schema.prisma`) | Project-specific (`schemas/process-todos-config.schema.json`, `skills/process-todos/SKILL.md`) |
| **User's suggestion followed blindly?** | N/A (evals don't suggest technologies) | No — user suggested "JSON Schema or Zod", analyst correctly rejected Zod |
| **i18n awareness** | None | Korean error messages included (matching project's Korean-speaking audience) |
| **Test specifications** | Generic test scenarios | Codebase-aware scenarios (e.g., testing BOM handling, empty file, git branch name constraints) |

**Key delta**: The production test produced todos that are **aware of what this project actually is**. The synthetic evals generate todos for an imaginary Next.js app. This test generated todos that reference real files (`skills/process-todos/SKILL.md`, `README.md`), understand the project's architecture (markdown-instruction-based plugin), and make technology decisions grounded in evidence (JSON Schema over Zod because no runtime exists).

---

## Issues, Surprises, and Friction Points

### 1. The analyst cannot actually be spawned (CRITICAL)

The SKILL.md says to use `Agent(subagent_type="process-todos:todo-analyst", ...)` but this is only available inside the Claude Code plugin runtime. When simulating the skill manually (or in an eval), the analyst agent cannot be spawned. The fallback ("perform the decomposition analysis yourself") works but loses the analyst's structured output format and its isolation as a separate concern.

**Suggestion**: SKILL.md should explicitly note that the analyst is a Claude Code agent and cannot be called from outside the plugin runtime. The fallback should say "follow the todo-analyst.md procedure directly" rather than just "perform the analysis yourself."

### 2. The skill assumes a code-centric project

SKILL.md's examples and guidance heavily assume the target project has source code (TypeScript, API routes, UI components, Prisma schemas). This project is a *meta-project* — its "source code" is markdown instructions. The skill guidance about "test specifications" and "type definitions" was awkward to apply: there are no types to define (no TS), and tests would need to be in a hypothetical test harness that doesn't exist yet.

**Suggestion**: Add a note in SKILL.md: "If the project has no conventional source code (e.g., it's a plugin, config repo, or documentation project), adapt the guidance accordingly — checklist items should reference the actual artifacts of the project rather than forcing code-centric patterns."

### 3. "Finer layer separation" mapped awkwardly to this feature

The SKILL.md says "When a feature spans data -> API -> UI, prefer 3 todos over 2." The config validation feature doesn't span data/API/UI — it spans schema definition -> instruction updates -> error UX. The mapping worked but required creative interpretation. The guidance could be more abstract: "separate the *definition* from the *integration* from the *user-facing polish*."

**Suggestion**: Generalize the layer separation guidance. Instead of only "data -> API -> state -> UI", add "For non-UI features, the analogous split is: definition/schema -> integration/wiring -> validation/error-handling/UX."

### 4. Default config values feel wrong for THIS project

The skill loaded defaults (`todo_path: docs/todos`, `type_check_command: npm run check-types`) which don't match this project at all (there are no `docs/todos` and no `npm run check-types`). The defaults are designed for target projects that use the plugin, not for the plugin's own codebase. This is fine in practice — the user would have a `.process-todos.json` in their own project — but it was confusing during testing.

**Not a bug, but worth noting**: The config defaults are designed for the plugin's *users*, not for the plugin itself.

### 5. Korean/English bilingual context was underspecified

The user prompt was in Korean. The SKILL.md doesn't give guidance on whether todo files should be in the user's language or in English. I defaulted to English (consistent with the eval outputs and the skill itself being in English), but included Korean in error message examples. The SKILL.md should probably state: "Write todo files in English, but use the user's language in error messages and user-facing text within checklist items."

### 6. No existing todos to check for numbering conflicts

SKILL.md says "Check for existing .md files in {todo_path}/" — but `docs/todos/` doesn't exist. The edge case guidance says to "mention them and ask whether new todos should be added alongside." For production, this check passed trivially. The eval environment also has no existing todos, so this edge case has never been tested.

---

## Concrete Suggestions for SKILL.md Improvements

### Priority 1 (Based on this test)

1. **Clarify analyst invocation context**: Add to Step 2: "The `todo-analyst` agent is only available inside the Claude Code plugin runtime. When running this skill in other contexts (manual testing, evals), follow the analysis procedure in `agents/todo-analyst.md` directly."

2. **Generalize layer separation**: In Step 3, add: "For features that don't follow the traditional data -> API -> UI pattern (e.g., config, tooling, documentation), apply the same principle: separate *definition/schema* from *integration/wiring* from *user-facing polish*."

3. **Add guidance for non-code projects**: In Step 3 or Step 4, add a note: "If the project doesn't have conventional source code (e.g., it's a plugin with markdown instructions, a config repo, or infrastructure-as-code), adapt checklist items to reference the project's actual artifacts rather than defaulting to TypeScript/React patterns."

### Priority 2 (General improvements)

4. **Specify output language**: Add: "Write todo file content in English. When checklist items include user-facing text (error messages, UI copy), use the same language as the user's original request."

5. **Document the analyst's value proposition in the skill**: The analyst produced the single most important insight of this test (no TypeScript runtime = Zod impossible). SKILL.md should emphasize that the analyst exists to *prevent bad technology assumptions*, not just to break ties between equally valid options.

6. **Add a "meta-project" eval case**: The current evals (password reset, profile page, chat system, typo fix) all assume a web app. A 5th eval case targeting a non-code project (plugin, CLI tool, config repo) would test the skill's adaptability and exercise the analyst in a meaningful way.
