# Todo-Creator Review Improvements Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Apply all 6 production test findings to SKILL.md, add a meta-project eval case, and validate with iteration 3.

**Architecture:** Targeted edits to `skills/todo-creator/SKILL.md` (5 text changes) and `skills/todo-creator/evals/evals.json` (1 new test case). Then run `run-evals.sh` to validate.

**Tech Stack:** Markdown, JSON, bash eval runner

---

### Task 1: Clarify analyst invocation context in SKILL.md Step 2

**Files:**
- Modify: `skills/todo-creator/SKILL.md:36-38`

**Step 1: Edit the analyst invocation paragraph**

In Step 2, replace the current "Making decisions during brainstorming" paragraph to add explicit runtime context and emphasize the analyst's value beyond tie-breaking:

```markdown
**Making decisions during brainstorming:** When brainstorming presents multiple approaches and a choice needs to be made, spawn a `todo-analyst` agent (`Agent(subagent_type="process-todos:todo-analyst", prompt=<decision question with options>)`). The analyst examines the codebase — existing patterns, conventions, dependencies — and returns a grounded recommendation. The analyst's primary value is **preventing bad technology assumptions** based on codebase evidence. For example, it might discover that the project has no TypeScript runtime, making a suggested library physically impossible — an insight that saves the worker from hitting a dead end. Use the analyst's recommendation to move brainstorming forward without blocking on the user for every decision.
```

**Step 2: Edit the brainstorming fallback paragraph**

Replace the current "If brainstorming skill is unavailable" paragraph with a version that explicitly references the analyst procedure file:

```markdown
**If brainstorming skill is unavailable** (e.g., running in a subagent without installed skills): perform the decomposition analysis yourself. Cover the same ground — major components, dependencies, affected code, architectural decisions — by reading the codebase directly. The structure matters more than having the brainstorming skill specifically.

**If todo-analyst agent is unavailable** (e.g., outside the Claude Code plugin runtime): follow the analysis procedure in `agents/todo-analyst.md` directly. The 4-step procedure (parse decision → read project context → find existing patterns → assess) works identically whether run by the agent or performed manually.
```

**Step 3: Verify the edit**

Read `skills/todo-creator/SKILL.md` lines 28-42 and confirm:
- Analyst paragraph mentions "preventing bad technology assumptions"
- Brainstorming fallback is unchanged
- New analyst fallback paragraph references `agents/todo-analyst.md` explicitly

**Step 4: Commit**

```bash
git add skills/todo-creator/SKILL.md
git commit -m "feat(todo-creator): clarify analyst invocation context and value proposition

Production test showed the analyst's primary value is preventing bad
technology assumptions (e.g., rejecting Zod in a no-runtime project),
not just breaking ties. Also added explicit fallback: follow
agents/todo-analyst.md directly when outside plugin runtime."
```

---

### Task 2: Generalize layer separation in SKILL.md Step 3

**Files:**
- Modify: `skills/todo-creator/SKILL.md:54-57`

**Step 1: Edit the layer separation guidance**

After the existing "Prefer finer layer separation" paragraph (which covers data → API → UI), add a new paragraph for non-UI features:

```markdown
**For features outside the traditional data → API → UI pattern** (config validation, tooling, documentation, CI/CD), apply the same principle with adapted layers: separate *definition/schema* from *integration/wiring* from *user-facing polish*. For example, a config validation feature splits into: (1) define the schema, (2) wire validation into the system, (3) polish error messages and edge cases.
```

**Step 2: Verify the edit**

Read `skills/todo-creator/SKILL.md` lines 54-62 and confirm:
- Original data → API → UI guidance is intact
- New paragraph follows it, covering non-UI features
- The example (config validation) is concrete

**Step 3: Commit**

```bash
git add skills/todo-creator/SKILL.md
git commit -m "feat(todo-creator): generalize layer separation for non-UI features

Add guidance for features outside data→API→UI: definition/schema →
integration/wiring → user-facing polish. Based on production test
where config validation didn't map to the web-app-centric layers."
```

---

### Task 3: Add non-code project guidance in SKILL.md Step 4

**Files:**
- Modify: `skills/todo-creator/SKILL.md:95-101`

**Step 1: Add non-code project note**

After the existing "Beyond code" section in Step 4 (line ~95), add a new subsection:

```markdown
**Non-code projects (plugins, config repos, documentation, infrastructure-as-code):**
Not every project has TypeScript files, API routes, or UI components. When the project's primary artifacts are markdown instructions, JSON/YAML configuration, or infrastructure definitions:
- Reference the project's *actual* artifacts in checklist items (e.g., `skills/process-todos/SKILL.md` instead of `src/lib/...`)
- Adapt "test specifications" to the project's testing reality — this might mean validation scripts, linting checks, or manual verification steps rather than unit tests
- Don't default to TypeScript/React patterns; examine what the project actually uses
```

**Step 2: Verify the edit**

Read `skills/todo-creator/SKILL.md` around the insertion point and confirm:
- Note appears after the "Beyond code" section
- References concrete examples (markdown, JSON/YAML, infrastructure)
- Doesn't repeat existing guidance

**Step 3: Commit**

```bash
git add skills/todo-creator/SKILL.md
git commit -m "feat(todo-creator): add guidance for non-code projects

Production test on this plugin (pure markdown, no TS/JS) showed the
skill defaults to code-centric patterns. New section guides adaptation
for plugins, config repos, and infrastructure-as-code projects."
```

---

### Task 4: Add output language convention in SKILL.md Step 4

**Files:**
- Modify: `skills/todo-creator/SKILL.md:65-66`

**Step 1: Add language convention**

At the start of Step 4 (after the "Create markdown files" line), add:

```markdown
**Language convention:** Write todo file content (titles, context paragraphs, checklist items) in English. When checklist items include user-facing text (error messages, UI copy, placeholder text), use the same language as the user's original request.
```

**Step 2: Verify the edit**

Read `skills/todo-creator/SKILL.md` around lines 65-70 and confirm:
- Language convention appears at the top of Step 4
- English for structural content, user's language for user-facing text

**Step 3: Commit**

```bash
git add skills/todo-creator/SKILL.md
git commit -m "feat(todo-creator): specify output language conventions

English for todo structure (titles, context, checklist items).
User's language for embedded user-facing text (error messages, UI copy).
Addresses ambiguity found in production test with Korean prompts."
```

---

### Task 5: Add meta-project eval case to evals.json

**Files:**
- Modify: `skills/todo-creator/evals/evals.json`

**Step 1: Add eval case id:5**

Add a 5th test case targeting a non-code project — a Claude Code plugin that needs a new feature. This exercises the skill's adaptability and would exercise the analyst if it were available:

```json
{
  "id": 5,
  "name": "meta-project-plugin-feature",
  "prompt": "이 Claude Code 플러그인에 설정 validation 기능을 추가하고 싶어. .process-todos.json 파일을 읽을 때 스키마 검증하고, 잘못된 설정이면 에러 메시지를 보여줘. JSON Schema나 Zod 쓸 수 있을 것 같은데 알아서 판단해줘.",
  "expected_output": "2-3개의 todo 파일. 프로젝트가 코드 없는 마크다운 플러그인임을 인식하고 Zod 대신 JSON Schema를 선택. 체크리스트가 마크다운/JSON 아티팩트를 참조.",
  "files": [],
  "assertions": {
    "baseline": [
      {
        "name": "appropriate-file-count",
        "description": "Creates 2-3 todo files (schema definition, integration, polish)"
      },
      {
        "name": "correct-markdown-format",
        "description": "Each file has: H1 title, context paragraph, and checklist with '- [ ]' items"
      },
      {
        "name": "checklist-items-are-concrete",
        "description": "Each checklist item describes a specific implementable action, not vague directives"
      }
    ],
    "discriminating": [
      {
        "name": "references-project-artifacts",
        "description": "Checklist items reference the project's actual artifacts (e.g., SKILL.md files, agents/*.md, plugin.json, .process-todos.json) rather than defaulting to src/lib/ or TypeScript file paths"
      },
      {
        "name": "adapts-to-non-code-project",
        "description": "Context paragraphs or checklist items acknowledge that this is a markdown/JSON plugin with no TypeScript runtime, and adapt recommendations accordingly (e.g., choosing JSON Schema over Zod, or noting that validation happens in skill instructions rather than compiled code)"
      },
      {
        "name": "includes-validation-approach",
        "description": "At least one todo specifies the validation mechanism with reasoning — not just 'add validation' but HOW validation works in a project without a code runtime"
      }
    ]
  }
}
```

**Step 2: Validate JSON syntax**

Run: `jq '.' skills/todo-creator/evals/evals.json`
Expected: Valid JSON output, 5 evals listed.

**Step 3: Commit**

```bash
git add skills/todo-creator/evals/evals.json
git commit -m "feat(evals): add meta-project eval case for non-code plugins

New test case (id:5) targets a Claude Code plugin with no TypeScript
runtime. Tests the skill's ability to adapt to non-code projects and
make codebase-aware technology decisions (JSON Schema over Zod).
Discriminating assertions check for project-artifact references and
runtime-awareness."
```

---

### Task 6: Run iteration 3 with all 5 eval cases

**Files:**
- Read: `skills/todo-creator/evals/run-evals.sh`
- Output: `skills/todo-creator-workspace/iteration-3/`

**Step 1: Dry run to verify setup**

Run: `bash skills/todo-creator/evals/run-evals.sh --dry-run`
Expected: Shows 5 test cases × 2 configs = 10 agent runs, iteration-3.

**Step 2: Run the full eval**

Run: `bash skills/todo-creator/evals/run-evals.sh --iteration-name iteration-3`
Expected: All 10 agents complete. benchmark.json and benchmark.md produced.

**Step 3: Review benchmark results**

Read `skills/todo-creator-workspace/iteration-3/benchmark.md` and check:
- with_skill overall pass rate (target: ≥95%)
- Discriminating delta (target: ≥+0.3 vs without_skill)
- New meta-project case: does `adapts-to-non-code-project` discriminate?
- Trivial case (id:4): does `scope-proportional-to-request` discriminate?
- Large case (id:3): still non-discriminating? (expected)

**Step 4: Document findings**

If results look good, update HANDOFF.md with iteration-3 results. If assertions need tuning, note which ones and why.

**Step 5: Commit benchmark results**

```bash
git add skills/todo-creator-workspace/iteration-3/
git add HANDOFF.md
git commit -m "feat(evals): iteration 3 results with SKILL.md improvements

Applied 6 production test findings. Results:
- with_skill: X% overall, Y% discriminating
- without_skill: X% overall, Y% discriminating
- New meta-project case: [discriminates/doesn't]
- Trivial case: [discriminates/doesn't]"
```
