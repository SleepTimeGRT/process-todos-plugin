# Handoff: todo-creator Skill Development

## Goal

Add a `todo-creator` skill to the `process-todos` plugin that turns natural language feature descriptions into well-structured todo markdown files, eliminating the need for users to manually write them.

## Current Progress

### Completed

1. **SKILL.md drafted and refined (v2)** — `skills/todo-creator/SKILL.md`
   - 5-step workflow: Load config → Brainstorm → Break down → Write files → Present & confirm
   - Leverages `/superpowers:brainstorming` for feature decomposition
   - **v2 additions**: brainstorming fallback, finer layer separation guide (data→API→state→UI), explicit guidance for test specs/type definitions/component props/error mappings in checklist items
   - `required_skills`: brainstorming, dx:handoff, test-driven-development, feature-dev

2. **todo-analyst agent created** — `agents/todo-analyst.md`
   - Haiku model, read-only tools (`Read`, `Grep`, `Glob`, `LS`)
   - Analyzes codebase patterns to make decisions during brainstorming
   - Returns recommendations with confidence levels (high/medium/low)
   - **Not yet exercised in evals** — no real codebase context in test cases

3. **Iteration 1 evaluation** — `skills/todo-creator-workspace/iteration-1/`
   - 3 test cases (simple/medium/large) × 2 configs (with/without skill) = 6 runs
   - All 12 assertions pass for both — assertions were non-discriminating
   - Qualitative comparison showed with-skill produces finer-grained decompositions

4. **Iteration 2 evaluation** — `skills/todo-creator-workspace/iteration-2/`
   - Same 3 test cases × 2 configs, now with **baseline + discriminating** assertions
   - 22 total assertions (12 baseline + 10 discriminating)
   - **Results**: with-skill 100% (22/22), without-skill 81.9% (18/22)
   - **Discriminating**: with-skill 100% (10/10), without-skill 70% (7/10)

### Files Map

```
skills/todo-creator/
  SKILL.md                          ← skill definition (v2)
  evals/evals.json                  ← test cases with baseline + discriminating assertions

agents/
  todo-analyst.md                   ← codebase analysis agent

skills/todo-creator-workspace/
  iteration-1/                      ← first eval round (non-discriminating)
    {simple,medium,large}/
      eval_metadata.json
      {with,without}_skill/
        outputs/*.md                ← generated todo files
        grading.json
        timing.json
    benchmark.json
    benchmark.md

  iteration-2/                      ← second eval round (discriminating)
    {simple,medium,large}/
      eval_metadata.json            ← updated assertions (baseline + discriminating)
      {with,without}_skill/
        outputs/*.md
        grading.json
        timing.json
    benchmark.json                  ← full results with run_summary and delta
    benchmark.md                    ← human-readable comparison
```

## What Worked

- **Splitting assertions into baseline + discriminating** — baseline assertions confirm both configs meet minimum quality (100%/100%); discriminating assertions measure skill's added value (100% vs 70%). This structure makes evaluation meaningful.
- **`includes-test-specifications` is the strongest discriminator** — with-skill always includes test file paths + specific test scenarios; without-skill consistently omits them for simple/medium features. This is the clearest signal of skill value.
- **Brainstorming fallback in SKILL.md** — adding "if brainstorming skill is unavailable, do the analysis yourself" made the skill work correctly in subagent eval environments where brainstorming isn't installed.
- **Parallel agent eval execution** — running 6 eval agents simultaneously (3 cases × 2 configs) then 6 grading agents in parallel made iteration 2 fast (~3 minutes total wall time).
- **Finer layer separation guidance** — explicitly telling the skill to separate data→API→state→UI produced consistently better architecture vs without-skill which varied between runs.

## What Didn't Work

- **Iteration 1 assertions were non-discriminating** — "checklist-items-are-concrete" and "concern-based-split" pass trivially for both configs. The problem: they define a floor that Sonnet already meets without any skill guidance.
- **`separates-data-layer` lost its discriminating power** — in iteration 1, without-skill bundled schema with API. In iteration 2, without-skill also separates them. This assertion is no longer a reliable discriminator (natural variance or Sonnet improvement).
- **Large test case doesn't discriminate** — for complex features (chat system), without-skill also passes all discriminating assertions. The skill's value is concentrated on simple/medium features. This means the eval suite over-indexes on a scenario where the skill isn't needed.
- **`includes-test-specifications` grading for large without-skill was borderline** — the grader passed it with "vitest and test WebSocket client" evidence but no explicit test file paths. The assertion description says "test file paths" but the grader was lenient.
- **No automated eval runner** — each iteration required manually crafting 6 eval agent prompts + 6 grading agent prompts. This is error-prone and slow for future iterations.

## Next Steps

1. **Tighten `includes-test-specifications` assertion** — require explicit test file paths (e.g., `src/__tests__/...test.ts`), not just framework mentions. This would make it discriminate for the large case too, improving overall discriminating pass rate delta.

2. **Description optimization** — run the skill-creator `scripts.run_loop` to improve skill triggering accuracy on diverse prompts (Korean/English, different phrasings).

3. **Production testing** — try the skill on a real project with `CLAUDE.md` and existing code. This would:
   - Exercise the todo-analyst agent (not tested in evals due to no codebase)
   - Validate the brainstorming integration end-to-end
   - Surface issues with the skill reading project conventions

4. ~~**Register in plugin.json**~~ — **RESOLVED**: Skills and agents are auto-discovered by convention. Claude Code scans `skills/` for subdirectories with `SKILL.md` and `agents/` for `.md` files. No explicit registration in `plugin.json` is needed. The `skills`/`agents` fields in the manifest are only for specifying *additional* scan locations (they supplement, not replace, the defaults). `todo-creator` will be available as `/process-todos:todo-creator` automatically.

5. **Build an eval runner** (optional) — a script or skill that automates: create dirs → spawn eval agents → spawn grading agents → aggregate benchmark. Would reduce iteration time from ~15 min manual to ~5 min automated.

6. **Add a 4th test case** — consider a "tiny" feature (e.g., "fix the typo in the header") to validate the edge case behavior described in SKILL.md.
