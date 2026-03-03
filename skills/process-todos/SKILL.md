---
description: Only invoke when the user explicitly runs /process-todos. 3-tier agent orchestration for sequential todo processing with git worktree isolation, configurable via .process-todos.json.
required_skills:
  - superpowers:brainstorming
  - dx:handoff
  - simplify
---

# Process Todos

Sequential todo ticket processor. Reads `{todo_path}/*.md` files and spawns `todo-worker` sub-agents to handle each ticket's full lifecycle (design -> plan -> implement).

## Lead Orchestration Procedure

### Step 0 — Load Configuration

1. Read `.process-todos.json` from the project root using the Read tool. If the file doesn't exist, use default values.
2. Extract these settings (defaults shown):
   - `todo_path`: `docs/todos` — directory containing todo markdown files
   - `type_check_command`: `npm run check-types` — pre-merge verification command
   - `branch_prefix`: `todo/` — git branch prefix for worktrees
   - `worker_model`: `null` — model for worker agent (null = system default, do not pass model parameter)
   - `merge_strategy`: `pr` — how to integrate completed work. `pr`: push branch and create a pull request via `gh pr create`. `merge`: merge branch directly into current branch
   - `pr_on_conflict`: `false` — only applies when `merge_strategy` is `merge`. If `true`, merge conflicts that would normally be skipped are instead pushed as a PR for manual review
3. Announce: "Config: todo_path={todo_path}, type_check_command={type_check_command}, branch_prefix={branch_prefix}, worker_model={worker_model}, merge_strategy={merge_strategy}, pr_on_conflict={pr_on_conflict}"

### Step 1 — Discover Todos

1. List all `.md` files in `{todo_path}/` directory using Glob
2. Sort alphabetically by filename
3. Filter out any file whose first line contains `<!-- skipped:` marker — these are previously-skipped todos
4. If no files remain: report "No todos found in {todo_path}/" and stop
5. Announce: "Found N todo(s): [filenames]. Processing sequentially."

### Step 2 — Process Each Todo

Maintain a `handoff_count` per todo (starts at 0). For each todo file (one at a time, in order):

1. Read the todo file content
2. Set up the worktree for this todo. `<todo-name>` is the filename without the `.md` extension.
   - **If `.claude/worktrees/<todo-name>` already exists** (previous run interrupted):
     - Reuse the existing worktree — it contains the previous worker's progress
     - If `HANDOFF.md` exists in the worktree: treat as a handoff (use handoff prompt in Step 2.4)
     - If no `HANDOFF.md`: use the first-attempt prompt
   - **If the directory does not exist:**
     - Check if branch `{branch_prefix}<todo-name>` already exists: `git branch --list {branch_prefix}<todo-name>`
     - Branch exists: `git worktree add .claude/worktrees/<todo-name> {branch_prefix}<todo-name>`
     - Branch does not exist: `git worktree add .claude/worktrees/<todo-name> -b {branch_prefix}<todo-name>`
3. Announce: "Processing [N/total]: [filename]"
4. Build the worker prompt using this base structure:

**Base template:**
```
{PREAMBLE}

**Config:**
- type_check_command: {type_check_command}
- branch_prefix: {branch_prefix}

**Worktree path:** <absolute path to .claude/worktrees/<todo-name>>

## Todo: <filename>
<full file content>

{EXTRA_CONTEXT}
```

**Preamble and extra context per scenario:**

| Scenario | Preamble | Extra Context |
|----------|----------|---------------|
| First attempt | `Process this todo ticket.` | *(none)* |
| Handoff continuation | `Continue this todo ticket from where the previous worker left off.` | `## Handoff Context\n<content of .claude/worktrees/<todo-name>/HANDOFF.md>` |
| Type error fix | `Continue this todo ticket — the previous worker completed all checklist items but the type check failed. Fix only the type errors below. Do not re-implement features or refactor existing work.` | `## Type Errors\n<full {type_check_command} output>` |

5. Spawn worker: `Agent(subagent_type="process-todos:todo-worker", prompt=<built prompt>, mode="dontAsk")`
   - If `worker_model` is set (not null), add `model="{worker_model}"` to the spawn call.
6. Wait for worker result

### Worker Response Contract

The worker (`todo-worker` agent) must return exactly one of these tags in its response:

| Status | Response Tag | Meaning |
|--------|-------------|---------|
| Done | `<result>DONE</result>` | All checklist items implemented and committed |
| Handoff | `<result>HANDOFF</result>` | Context limit reached, HANDOFF.md written in worktree |

Any response containing neither tag is treated as "unexpected" — see Step 3.

### Step 3 — Handle Worker Result

Parse the worker's return message.

**If contains `<result>DONE</result>` in the response:**
1. Run type check in worktree: `cd .claude/worktrees/<todo-name> && {type_check_command}`
2. **If type check passes:** run code review before merging.
   1. Run `/simplify` on the worktree diff (`cd .claude/worktrees/<todo-name> && git diff main...HEAD`) to review all changes the worker produced
   2. **If review finds secrets or API keys in the diff** (e.g., hardcoded tokens, passwords, private keys, `.env` values committed): this is a **critical failure**. Write HANDOFF.md in the worktree documenting the exposed secrets and their locations, skip this todo (see "Skipping a Todo"), and proceed to the next todo. Do NOT merge.
   3. If review suggests non-critical improvements: apply them in the worktree, commit, and continue
   4. **Integrate based on `merge_strategy`:**
      - **`merge`**: Merge the worktree branch into the current branch: `git merge {branch_prefix}<todo-name> --no-edit`. On merge conflict, see step 3 below.
      - **`pr`**: Push the branch (`git push -u origin {branch_prefix}<todo-name>`) and create a PR (`gh pr create --head {branch_prefix}<todo-name> --title "<todo title>" --body "<summary of changes>"`). Keep the worktree and branch intact (the PR reviewer may request changes).
   5. **If `merge` strategy:** Remove the worktree: `git worktree remove .claude/worktrees/<todo-name>`, delete the branch: `git branch -d {branch_prefix}<todo-name>`, delete the todo file: `{todo_path}/<filename>`
   6. **If `pr` strategy:** Delete the todo file: `{todo_path}/<filename>` (worktree and branch remain until PR is merged)
   7. Announce: "Completed [N/total]: [filename]" (include PR URL if `pr` strategy)
   8. Proceed to next todo
3. **If merge fails (conflicts)** (only applies when `merge_strategy` is `merge`):
   1. Assess conflict size: `git diff --name-only --diff-filter=U` to list conflicting files
   2. **Small/localized conflicts** (1-2 files, conflicts are straightforward): resolve the conflicts automatically, then continue with the merge
   3. **Large/ambiguous conflicts** (3+ files, or conflicts involve complex logic): abort the merge (`git merge --abort`).
      - **If `pr_on_conflict` is `true`:** push the branch and create a PR instead (`gh pr create`), noting the merge conflict in the PR body. Delete the todo file. Proceed to next todo.
      - **Otherwise:** write HANDOFF.md in worktree documenting the conflict details, skip this todo (see "Skipping a Todo"), and proceed to the next todo
4. **If type check fails:**
   1. Increment `handoff_count` for this todo
   2. If 3rd attempt: write HANDOFF.md in worktree documenting the persistent type errors, skip this todo (see "Skipping a Todo"), and proceed to the next todo
   3. Spawn a new worker using the **type error prompt** from Step 2.4 with the full `{type_check_command}` output
   4. Announce: "Type check failed for [filename]. Spawning worker to fix. (attempt N/3)"

**If contains `<result>HANDOFF</result>` in the response:**
1. If this is the 3rd handoff for the same todo: keep the worktree and branch intact, skip this todo (see "Skipping a Todo"), and proceed to the next todo — the ticket may be too large for automated processing
2. Read `HANDOFF.md` from the worktree: `.claude/worktrees/<todo-name>/HANDOFF.md`
3. Increment `handoff_count` for this todo
4. Spawn a new worker with handoff context and the **same worktree path** (go back to Step 2.4) — the worktree already contains the previous worker's commits and HANDOFF.md
5. Announce: "Worker handed off [filename] (attempt N/3). Spawning fresh worker to continue."

**If neither (unexpected):**
1. If this is the first unexpected result for this todo: retry once by spawning a new worker with the same prompt and worktree path
2. If retry also returns an unexpected result: write HANDOFF.md in worktree documenting both unexpected responses, skip this todo (see "Skipping a Todo"), and proceed to the next todo

### Skipping a Todo

When a failure path requires skipping a todo (see Step 3), the orchestrator:
1. Writes `HANDOFF.md` in the worktree (if not already present) documenting the failure and any partial progress
2. Prepends `<!-- skipped: <reason> -->` as the first line of the todo file in `{todo_path}/`
3. Adds the todo to the skipped list for the final summary
4. Proceeds to the next todo

**Re-enabling a skipped todo:** Manually remove the `<!-- skipped: ... -->` first line from the todo file. On the next `/process-todos` run, Step 1 will pick it up again. The worktree and branch from the previous attempt are preserved, so the new worker will resume from where the previous one left off.

### Step 4 — Summary

After all todos are processed (or stopped):

```
## Todo Processing Complete

- Processed: N/M tickets
- Completed: [list of completed filenames]
- Skipped/Failed: [list, if any]
- Handoffs: [filename (N handoffs), ...] — only list tickets that required handoffs
```

## Rules

- **One todo at a time** — never process in parallel
- **Never modify todo files** — only delete on successful completion, or prepend skip marker on failure
- **Sequential order** — alphabetical by filename
- **Never stop** — all failure paths skip the current todo and proceed to the next; never block on user input mid-run
- **Clean up on completion** — delete both todo file and any handoff artifacts
- **One worktree per ticket** — create once, reuse across handoffs, merge and remove on completion
- **HANDOFF.md is in .gitignore** — never commit it; it persists in the worktree between handoff workers
