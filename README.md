# process-todos

A Claude Code plugin that processes todo markdown files using a 3-tier agent orchestration system. A lead orchestrator reads todo files, spawns worker agents in isolated git worktrees, and processes each todo sequentially with automatic handoff support.

## Installation

```bash
claude plugin add <username>/process-todos-plugin
```

## Configuration

Place a `.process-todos.json` file in your project root:

```json
{
  "todo_path": "docs/todos",
  "type_check_command": "npm run check-types",
  "branch_prefix": "todo/",
  "worker_model": null
}
```

| Setting | Default | Description |
|---|---|---|
| `todo_path` | `docs/todos` | Directory containing todo markdown files |
| `type_check_command` | `npm run check-types` | Command run before merge to verify code compiles |
| `branch_prefix` | `todo/` | Git branch prefix for worktree branches |
| `worker_model` | `null` (system default) | Model for worker agent (e.g., `"sonnet"`, `"opus"`) |

## Usage

Run `/process-todos` in Claude Code. The plugin will discover all `.md` files in the configured `todo_path` and process them one by one.

## Todo File Format

Todo files are standard markdown with checklist items:

```markdown
# Add user authentication

- [ ] Create auth middleware
- [ ] Add login endpoint
- [ ] Add session management
```

Place these files as `.md` files inside the configured `todo_path` directory.

## How It Works

The plugin uses a 3-tier agent system:

1. **Lead orchestrator** — reads todo files from the configured path, creates a git worktree per todo on a dedicated branch, and spawns a worker agent for each one sequentially.

2. **Worker agents** — run inside the worktree, assess task complexity, and chain skills as needed (brainstorming → planning → executing). When done, they run the type check and merge back to the main branch.

3. **Researcher agents** — spawned by workers to perform web lookups and external research. Kept separate to preserve the worker's context window.

Additional behaviors:

- **Automatic handoff** — if a worker approaches its context limit mid-task, it writes a handoff file and a fresh worker picks up where it left off. Max 3 retries per todo.
- **Pre-merge type checking** — the configured `type_check_command` is run before merging. If it fails, the worker attempts to fix the issues automatically.
- **Merge conflict handling** — if a merge conflict occurs, the worktree is preserved and reported for manual resolution.

## Troubleshooting

**"No todos found"**
Check that `todo_path` in `.process-todos.json` points to the correct directory and that it contains `.md` files with `- [ ]` checklist items.

**Type check fails repeatedly**
Verify that `type_check_command` runs successfully in your project before using the plugin (e.g., run `npm run check-types` manually). Ensure all dependencies are installed.

**Merge conflicts**
The worktree is preserved when a conflict occurs. Resolve the conflict manually in the worktree directory and merge it yourself.

**Handoff loop (fails after 3 retries)**
The todo may be too large or complex for a single agent to complete. Consider splitting it into smaller, more focused todo files.
