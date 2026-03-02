---
description: Only invoke when the user explicitly runs /process-todos. 3-tier agent orchestration for sequential todo processing with git worktree isolation, configurable via .process-todos.json.
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
3. Announce: "Config: todo_path={todo_path}, type_check_command={type_check_command}, branch_prefix={branch_prefix}, worker_model={worker_model}"

### Step 1 — Discover Todos

1. List all `.md` files in `{todo_path}/` directory using Glob
2. Sort alphabetically by filename
3. If no files found: report "No todos found in {todo_path}/" and stop
4. If >3 files found: ask user to confirm batch processing before proceeding
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
4. Build the worker prompt:

**If first attempt (no handoff):**
```
Process this todo ticket.

**Config:**
- type_check_command: {type_check_command}
- branch_prefix: {branch_prefix}

**Worktree path:** <absolute path to .claude/worktrees/<todo-name>>

## Todo: <filename>
<full file content>
```

**If continuing from handoff:**
```
Continue this todo ticket from where the previous worker left off.

**Config:**
- type_check_command: {type_check_command}
- branch_prefix: {branch_prefix}

**Worktree path:** <absolute path to .claude/worktrees/<todo-name>>

## Todo: <filename>
<full file content>

## Handoff Context
<content of .claude/worktrees/<todo-name>/HANDOFF.md>
```

**If fixing type errors (DONE returned but type check failed):**
```
Continue this todo ticket — the previous worker completed all checklist items
but the type check failed. Fix only the type errors below.
Do not re-implement features or refactor existing work.

**Config:**
- type_check_command: {type_check_command}
- branch_prefix: {branch_prefix}

**Worktree path:** <absolute path to .claude/worktrees/<todo-name>>

## Todo: <filename>
<full file content>

## Type Errors
<full {type_check_command} output>
```

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
2. **If type check passes:**
   1. Merge the worktree branch into the current branch: `git merge {branch_prefix}<todo-name> --no-edit`
   2. Remove the worktree: `git worktree remove .claude/worktrees/<todo-name>`
   3. Delete the branch: `git branch -d {branch_prefix}<todo-name>`
   4. Delete the todo file: `{todo_path}/<filename>`
   5. Announce: "Completed [N/total]: [filename]"
   6. Proceed to next todo
3. **If merge fails (conflicts):**
   1. Abort the merge: `git merge --abort`
   2. Keep the worktree and branch intact for manual resolution
   3. Announce: "Merge conflict for [filename]. Worktree preserved at `.claude/worktrees/<todo-name>`. Skipping to next todo."
   4. Add to skipped list for the final summary
4. **If type check fails:**
   1. Increment `handoff_count` for this todo
   2. If 3rd attempt: stop and ask the user how to proceed
   3. Spawn a new worker using the **type error prompt** from Step 2.4 with the full `{type_check_command}` output
   4. Announce: "Type check failed for [filename]. Spawning worker to fix. (attempt N/3)"

**If contains `<result>HANDOFF</result>` in the response:**
1. If this is the 3rd handoff for the same todo: stop and ask the user how to proceed — the ticket may be too large for automated processing
2. Read `HANDOFF.md` from the worktree: `.claude/worktrees/<todo-name>/HANDOFF.md`
3. Increment `handoff_count` for this todo
4. Spawn a new worker with handoff context and the **same worktree path** (go back to Step 2.4) — the worktree already contains the previous worker's commits and HANDOFF.md
5. Announce: "Worker handed off [filename] (attempt N/3). Spawning fresh worker to continue."

**If neither (unexpected):**
1. If this is the first unexpected result for this todo: retry once by spawning a new worker with the same prompt and worktree path
2. If retry also returns an unexpected result: merge the worktree branch to preserve any partial progress, then report both responses to user and ask how to proceed (skip / stop)

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
- **Never modify todo files** — only delete on successful completion
- **Sequential order** — alphabetical by filename
- **User confirmation** — ask before batch processing >3 todos
- **Clean up on completion** — delete both todo file and any handoff artifacts
- **One worktree per ticket** — create once, reuse across handoffs, merge and remove on completion
- **HANDOFF.md is in .gitignore** — never commit it; it persists in the worktree between handoff workers
