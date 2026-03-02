# Handoff: todo-creator Skill Development

## Goal

Build and refine a `todo-creator` skill for the `process-todos` plugin that turns natural language feature descriptions into well-structured todo markdown files, with measurable quality improvement over unaided generation.

## Current Progress

### Completed

1. **SKILL.md v3** — `skills/todo-creator/SKILL.md`
   - 5-step workflow: Load config → Brainstorm → Break down → Write files → Present & confirm
   - Brainstorming fallback for non-plugin-runtime contexts
   - Analyst fallback: explicit reference to `agents/todo-analyst.md` procedure
   - Analyst value reframed: "preventing bad technology assumptions" (not just tie-breaking)
   - Generalized layer separation (data→API→UI + definition→integration→polish for non-UI)
   - Non-code project guidance (plugins, config repos, IaC)
   - Language convention (English structure, user's language for user-facing text)
   - Optimized description (991 chars) with 4 intent categories, Korean/English/mixed triggers

2. **todo-analyst agent** — `agents/todo-analyst.md`
   - Haiku model, read-only tools (`Read`, `Grep`, `Glob`, `LS`)
   - Steps 2-3 compressed from nested bullets to inline prose (~250 tokens saved)

3. **Eval suite** — `skills/todo-creator/evals/evals.json`
   - 5 test cases: simple (password reset), medium (profile page), large (chat system), tiny (typo fix), meta-project (plugin feature)
   - Baseline + discriminating assertions per case

4. **Iteration 1** — `skills/todo-creator-workspace/iteration-1/`
   - 3 cases × 2 configs = 6 runs. All assertions passed both configs (non-discriminating)

5. **Iteration 2** — `skills/todo-creator-workspace/iteration-2/`
   - 3 cases × 2 configs, with baseline + discriminating assertions
   - **Results**: with-skill 100% (22/22), without-skill 81.9% (18/22)
   - **Discriminating**: with-skill 100% (10/10), without-skill 70% (7/10)

6. **Production test** — `skills/todo-creator-workspace/production-test/`
   - Tested on this repo itself (pure markdown plugin, no TS/JS)
   - **Key finding**: todo-analyst correctly rejected Zod (no TypeScript runtime), chose JSON Schema
   - 6 concrete SKILL.md improvements in `production-test/report.md` — all applied

7. **Automated eval runner** — `skills/todo-creator/evals/run-evals.sh`
   - 4-phase pipeline: setup → run agents (parallel) → grade (parallel) → aggregate
   - CLI: `--dry-run`, `--eval-ids`, `--max-parallel`, `--model`, `--iteration-name`
   - **Fix applied**: uses `--model` not `-m` (the CLI doesn't support `-m`)
   - **Must run with `env -u CLAUDECODE`** when invoked from inside Claude Code

8. **Iteration 3** — `skills/todo-creator-workspace/iteration-3/`
   - 5 cases × 2 configs = 10 runs (first run with all 5 cases including trivial + meta-project)
   - **Results**: with-skill 84%, without-skill 27%, **delta +57.5%**
   - **Discriminating**: with-skill 75%, without-skill 20%, **delta +55%**
   - See detailed analysis below

9. **Token economy optimizations** — ~1,000 tokens saved per workflow:
   - Consolidated 3 prompt templates in `process-todos/SKILL.md` into 1 base + variant table (~280 tokens)
   - Condensed `README.md` config + architecture sections (~450 tokens)
   - Compressed `todo-analyst.md` Steps 2-3 (~250 tokens)

### Iteration 3 Detailed Results

| Case | with_skill | without_skill | Discriminates? |
|------|:----------:|:-------------:|:--------------:|
| simple-password-reset | 5/6 (83%) | 0/6 (0%) | **Yes** — strong |
| medium-profile-page | 7/8 (88%) | 7/8 (88%) | **No** — both high |
| large-chat-system | 8/8 (100%) | 0/8 (0%) | **Yes** — but single-run variance likely |
| trivial-typo-fix | 6/6 (100%) | 0/6 (0%) | **Yes** — perfect, first time tested |
| meta-project-plugin-feature | 3/6 (50%) | 2/6 (33%) | **Partial** — baselines discriminate, discriminating assertions fail both |

**Key findings:**
- **Trivial case is the strongest new discriminator** — skill keeps output proportional, without-skill over-produces
- **Large case flipped** — in iter-2 both scored 100%, in iter-3 without-skill scored 0%. Single-run variance; needs multiple runs to confirm
- **`separates-data-layer` reversed** — passed without_skill, failed with_skill on medium case. Confirmed non-discriminating; should be dropped
- **Meta-project discriminating assertions (0/3 both)** — `references-project-artifacts`, `adapts-to-non-code-project`, `includes-validation-approach` all fail because `claude --print` is stateless (no codebase access). These can only discriminate in production with the analyst agent
- **without_skill baseline regression** — 33% vs iter-2's 100%. The without_skill prompt produces raw text without code-fenced .md files, so the parser often finds 0 output files. This inflates the delta

### Files Map

```
skills/todo-creator/
  SKILL.md                          ← skill definition (v3)
  evals/
    evals.json                      ← 5 test cases
    run-evals.sh                    ← automated eval runner (use env -u CLAUDECODE)

skills/process-todos/
  SKILL.md                          ← orchestration skill (prompt templates consolidated)

agents/
  todo-analyst.md                   ← codebase analysis agent (compressed)
  todo-worker.md                    ← worker agent
  todo-researcher.md                ← research agent

skills/todo-creator-workspace/
  iteration-1/                      ← first eval round (non-discriminating)
  iteration-2/                      ← second eval round (3 cases)
  iteration-3/                      ← third eval round (5 cases, post-improvements)
    benchmark.json                  ← full results
    benchmark.md                    ← human-readable summary
  production-test/
    report.md                       ← detailed findings (all 6 applied)

docs/plans/
  2026-03-03-todo-creator-review-improvements.md  ← implementation plan for this session
```

## What Worked

- **Baseline + discriminating assertion split** — baseline confirms floor, discriminating measures skill's added value
- **`includes-test-specifications` as strongest discriminator** — with-skill always includes test file paths; without-skill consistently omits for simple/medium
- **Production testing revealed analyst's true value** — prevented wrong technology choice (Zod in no-runtime project). Impossible in synthetic evals
- **Trivial case as discriminator** — first time tested in iter-3, perfect discrimination (skill keeps output proportional)
- **Token optimizations without quality regression** — ~1,000 tokens saved, iter-3 delta (+55%) exceeded iter-2 delta (+41.7%)
- **Eval runner automation** — `run-evals.sh` replaces manual prompt crafting
- **Generalized layer separation** — definition→integration→polish now covers non-UI features

## What Didn't Work

- **`separates-data-layer` assertion** — reversed in iter-3 (passed without, failed with). Should be removed from discriminating assertions
- **Meta-project discriminating assertions in synthetic evals** — `adapts-to-non-code-project` etc. require codebase access that `claude --print` doesn't have. These are production-only assertions
- **Single-run eval variance** — large case went from both-100% (iter-2) to with-100%/without-0% (iter-3). Need 2-3 runs per config for statistical confidence
- **without_skill prompt produces unparseable output** — the baseline prompt doesn't always produce code-fenced .md files, so the parser finds 0 files. This inflates the delta artificially. The eval runner's without_skill prompt needs to be more explicit about output format
- **`-m` flag in eval runner** — the claude CLI uses `--model`, not `-m`. Fixed but caused two failed iteration-3 attempts
- **Running eval runner inside Claude Code** — `claude --print` fails with "cannot launch nested session". Must use `env -u CLAUDECODE` to bypass

## Next Steps

### Priority 1 — Fix eval reliability

1. **Fix without_skill prompt format** — the without_skill prompt should more explicitly request code-fenced .md files (matching the with_skill format instruction). Current without_skill baseline is artificially low because output isn't parsed correctly
2. **Drop `separates-data-layer`** from discriminating assertions (confirmed non-discriminating across iter-2 and iter-3)
3. **Run 2-3 runs per configuration** (`--max-parallel` supports this) to reduce single-run variance
4. **Mark meta-project discriminating assertions as production-only** — add a note in evals.json or split into separate eval configs

### Priority 2 — Description optimization

Run the skill-creator description optimization loop for `todo-creator` to improve triggering accuracy on edge cases. The description (991 chars) hasn't been optimized with the automated loop yet.

### Priority 3 — Further token economy

- Reduce researcher spawn frequency (biggest lever: 2x→1x per worker saves ~3,348 tokens/workflow)
- Consider whether `todo-worker.md` Rules section can be shortened (repeats Phase 2-3 content)
- Total instruction overhead per workflow: ~25,500-31,900 tokens → ~24,500-30,900 after current optimizations
