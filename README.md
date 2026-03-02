# process-todos

A Claude Code plugin that processes todo markdown files using a 3-tier agent orchestration system. A lead orchestrator reads todo files, spawns worker agents in isolated git worktrees, and processes each todo sequentially with automatic handoff support.

## Installation

```bash
claude plugin add <username>/process-todos-plugin
```

## Configuration

Create `.process-todos.json` in your project root to customize behavior:

```json
{
  "todo_path": "docs/todos",
  "type_check_command": "npm run check-types",
  "branch_prefix": "todo/",
  "worker_model": null
}
```

All fields are optional — defaults shown above.

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

The plugin uses a 3-tier agent orchestration: a lead agent reads todos sequentially, spawns worker agents in isolated git worktrees, and handles handoffs when workers hit context limits. Workers can delegate research to lightweight researcher agents to preserve their own context.

Run `/process-todos` to start processing. Use the `todo-creator` skill to generate well-structured todo files from natural language descriptions.

## Troubleshooting

**"No todos found"**
Check that `todo_path` in `.process-todos.json` points to the correct directory and that it contains `.md` files with `- [ ]` checklist items.

**Type check fails repeatedly**
Verify that `type_check_command` runs successfully in your project before using the plugin (e.g., run `npm run check-types` manually). Ensure all dependencies are installed.

**Merge conflicts**
The worktree is preserved when a conflict occurs. Resolve the conflict manually in the worktree directory and merge it yourself.

**Handoff loop (fails after 3 retries)**
The todo may be too large or complex for a single agent to complete. Consider splitting it into smaller, more focused todo files.
