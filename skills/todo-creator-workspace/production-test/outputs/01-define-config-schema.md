# Define Configuration Schema and Validation Types

The process-todos plugin reads `.process-todos.json` at runtime using Claude Code's `Read` tool, but currently has no validation — any malformed JSON or unexpected field silently passes through. This todo establishes the authoritative schema definition and the validation logic. Since the plugin has no JavaScript/TypeScript runtime (it is a pure markdown/JSON plugin interpreted by Claude Code), the schema must be defined as a JSON Schema document that the skill instructions reference, rather than using Zod or a programmatic library. The JSON Schema file serves as both documentation and machine-readable contract.

- [ ] Create `schemas/process-todos-config.schema.json` with a JSON Schema (draft 2020-12) defining:
  ```json
  {
    "type": "object",
    "properties": {
      "todo_path": { "type": "string", "default": "docs/todos", "description": "Directory containing todo markdown files" },
      "type_check_command": { "type": "string", "default": "npm run check-types", "description": "Command run before merge to verify code compiles" },
      "branch_prefix": { "type": "string", "pattern": "^[a-zA-Z0-9_-]+/$", "default": "todo/", "description": "Git branch prefix for worktrees (must end with /)" },
      "worker_model": { "type": ["string", "null"], "enum": ["sonnet", "opus", "haiku", null], "default": null, "description": "Model for worker agent (null = system default)" }
    },
    "additionalProperties": false
  }
  ```
- [ ] Add a `description` and `$id` field to the schema for self-documentation (e.g., `"$id": "https://github.com/process-todos/config-schema"`)
- [ ] Verify the schema is valid JSON Schema by running `npx ajv validate --spec=draft2020 -s schemas/process-todos-config.schema.json` (install `ajv-cli` as a dev dependency if needed, or validate via an online tool)
- [ ] Write tests in `schemas/__tests__/config-schema.test.ts` using `ajv` to validate the schema against test fixtures:
  - Valid: empty object `{}` (all defaults apply)
  - Valid: `{ "todo_path": "tasks", "branch_prefix": "feature/" }`
  - Invalid: `{ "todo_path": 123 }` (wrong type for todo_path)
  - Invalid: `{ "branch_prefix": "no-trailing-slash" }` (pattern violation)
  - Invalid: `{ "worker_model": "gpt-4" }` (not in enum)
  - Invalid: `{ "unknown_field": true }` (additionalProperties: false)
