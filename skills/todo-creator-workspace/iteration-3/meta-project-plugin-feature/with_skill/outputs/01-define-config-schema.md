# Define Zod Schema for .process-todos.json

This schema is the source of truth for what a valid process-todos config looks like.
Defining it separately from the validation wiring makes the shape easy to update
and lets the worker's type checker catch bad config accesses at compile time.
Assume no external storage or auth — schema validation runs entirely client-side.

- [ ] Create `schemas/process-todos-config.ts` (or `.js` if the plugin has no TS build step) exporting a `ProcessTodosConfigSchema` Zod object
- [ ] Define the following fields in the schema:
  - `todo_path`: `z.string().min(1)` — path to the todos directory, defaults to `"docs/todos"`
  - `type_check_command`: `z.string().optional()` — optional shell command to run type checks
  - `branch_prefix`: `z.string().optional().default("todo/")` — git branch name prefix
- [ ] Use `z.object({ ... }).strict()` so unrecognized keys produce a validation error instead of being silently ignored
- [ ] Export the inferred TypeScript type: `export type ProcessTodosConfig = z.infer<typeof ProcessTodosConfigSchema>`
- [ ] Export a `DEFAULT_CONFIG` constant matching the schema defaults:
  ```ts
  export const DEFAULT_CONFIG: ProcessTodosConfig = {
    todo_path: "docs/todos",
    branch_prefix: "todo/",
  }
  ```
- [ ] Write tests in `schemas/__tests__/process-todos-config.test.ts`:
  - (a) valid full config passes with no errors
  - (b) valid minimal config (only `todo_path`) passes
  - (c) unknown key (e.g., `{ todo_path: "x", unknown_field: true }`) fails with a message containing the key name
  - (d) empty string for `todo_path` fails validation
  - (e) `branch_prefix` of non-string type (e.g., number) fails with type error message