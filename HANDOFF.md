# Handoff: todo-creator Skill Development

## Goal

Build and refine a `todo-creator` skill for the `process-todos` plugin that turns natural language feature descriptions into well-structured todo markdown files, with measurable quality improvement over unaided generation.

## Current Progress

### Completed

1. **SKILL.md v2** — `skills/todo-creator/SKILL.md`
   - 5-step workflow: Load config → Brainstorm → Break down → Write files → Present & confirm
   - Brainstorming fallback for non-plugin-runtime contexts
   - Finer layer separation guide (data→API→state→UI)
   - Optimized description (991 chars) with 4 intent categories, Korean/English/mixed triggers, clear boundary with `process-todos` skill

2. **todo-analyst agent** — `agents/todo-analyst.md`
   - Haiku model, read-only tools (`Read`, `Grep`, `Glob`, `LS`)
   - Returns confidence-leveled recommendations grounded in codebase evidence

3. **Eval suite** — `skills/todo-creator/evals/evals.json`
   - 5 test cases: simple (password reset), medium (profile page), large (chat system), tiny (typo fix), meta-project (plugin feature)
   - Baseline + discriminating assertions per case
   - `includes-test-specifications` tightened to require explicit file paths, not just framework mentions

4. **Iteration 1 evaluation** — `skills/todo-creator-workspace/iteration-1/`
   - 3 cases × 2 configs = 6 runs. All assertions passed both configs (non-discriminating)

5. **Iteration 2 evaluation** — `skills/todo-creator-workspace/iteration-2/`
   - 3 cases × 2 configs, with baseline + discriminating assertions
   - **Results**: with-skill 100% (22/22), without-skill 81.9% (18/22)
   - **Discriminating**: with-skill 100% (10/10), without-skill 70% (7/10)

6. **Production test** — `skills/todo-creator-workspace/production-test/`
   - Tested on this repo itself (pure markdown plugin, no TS/JS)
   - **Key finding**: todo-analyst correctly rejected Zod (no TypeScript runtime), chose JSON Schema — codebase-aware decision impossible in synthetic evals
   - 6 concrete SKILL.md improvement suggestions in `production-test/report.md`

7. **Automated eval runner** — `skills/todo-creator/evals/run-evals.sh`
   - 4-phase pipeline: setup → run agents (parallel) → grade (parallel) → aggregate
   - CLI: `--dry-run`, `--eval-ids`, `--max-parallel`, `--model`, `--iteration-name`

8. **Production test improvements applied** — all 6 suggestions from `production-test/report.md` implemented:
   - Analyst invocation: explicit plugin-runtime context + fallback to `agents/todo-analyst.md` procedure
   - Analyst value: reframed from "tie-breaking" to "preventing bad technology assumptions"
   - Layer separation: generalized for non-UI features (definition → integration → polish)
   - Non-code project guidance: standalone paragraph in Step 4
   - Language convention: English for structure, user's language for user-facing text
   - 5th eval case: `meta-project-plugin-feature` targeting non-code plugin

9. **Token economy optimizations** — ~1,000 tokens saved per workflow:
   - Consolidated 3 prompt templates in `process-todos/SKILL.md` into 1 base + variant table (~280 tokens)
   - Condensed `README.md` config + architecture sections (~450 tokens)
   - Compressed `todo-analyst.md` Steps 2-3 from nested bullets to inline prose (~250 tokens)

### Files Map

```
skills/todo-creator/
  SKILL.md                          ← skill definition (v2, optimized description)
  evals/
    evals.json                      ← 5 test cases (simple/medium/large/tiny/meta-project)
    run-evals.sh                    ← automated eval runner

agents/
  todo-analyst.md                   ← codebase analysis agent

skills/todo-creator-workspace/
  iteration-1/                      ← first eval round (non-discriminating)
  iteration-2/                      ← second eval round (discriminating)
  production-test/
    outputs/*.md                    ← generated todos for config validation feature
    report.md                       ← detailed findings + 6 SKILL.md improvements
```

## What Worked

- **Baseline + discriminating assertion split** — baseline confirms floor quality (both 100%), discriminating measures skill's added value (100% vs 70%). Makes evaluation meaningful.
- **`includes-test-specifications` as strongest discriminator** — with-skill always includes test file paths + scenarios; without-skill consistently omits them for simple/medium features.
- **Tightened assertions with explicit exclusion clauses** — "not just framework names like 'vitest' or 'jest'" makes grader behavior deterministic. Solved the borderline-pass problem from iteration 2.
- **Production testing revealed analyst's true value** — analyst prevented a wrong technology choice (Zod in a no-runtime project). This insight is impossible in synthetic evals.
- **Eval runner automation** — `run-evals.sh` replaces ~15 min of manual prompt crafting per iteration.
- **Brainstorming fallback** — "if brainstorming skill is unavailable, do the analysis yourself" made the skill work in subagent/eval environments.

## What Didn't Work

- **Iteration 1 assertions were non-discriminating** — "checklist-items-are-concrete" and "concern-based-split" pass trivially. They define a floor Sonnet already meets without skill guidance.
- **`separates-data-layer` lost discriminating power** — without-skill also separates schema in iteration 2. No longer a reliable discriminator.
- **Large test case doesn't discriminate well** — for complex features, without-skill also passes all assertions. Skill's value is strongest on simple/medium features where it "raises the floor."
- **todo-analyst can't be spawned outside plugin runtime** — `Agent(subagent_type=...)` only works inside Claude Code. Evals and manual tests must follow the analyst's procedure directly.
- **SKILL.md assumes code-centric projects** — examples reference TypeScript, API routes, Prisma. Non-code projects (plugins, config repos) require creative reinterpretation.
- **"Finer layer separation" too web-app-specific** — "data → API → state → UI" doesn't map to config validation or tooling features.

## Next Steps

### Priority 1 — Run iteration 3 with eval runner

All 6 production test improvements + token optimizations applied. Validate with full eval run:

```bash
bash skills/todo-creator/evals/run-evals.sh --iteration-name iteration-3
```

Expected to verify:
- New meta-project case (id:5): does `adapts-to-non-code-project` discriminate?
- Trivial case (id:4): does `scope-proportional-to-request` discriminate?
- Large case (id:3): still non-discriminating? (expected)
- Overall delta maintained or improved after SKILL.md changes
- Token optimizations didn't regress quality

### Priority 2 — Description optimization

Run the skill-creator description optimization loop for `todo-creator` to improve triggering accuracy on edge cases.

### Priority 3 — Further token economy work

- Reduce researcher spawn frequency (biggest lever: 2x→1x per worker saves ~3,348 tokens/workflow)
- Consider whether `todo-worker.md` Rules section can be shortened (repeats Phase 2-3 content)
