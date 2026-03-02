Looking at this request, I'll create structured todo files for adding config validation to the process-todos plugin. Since this is a Claude Code plugin that reads `.process-todos.json`, I'll recommend **Zod** — it's a better fit than JSON Schema for a TypeScript/JS runtime environment because it gives you both validation and type inference in one step, with no extra deps needed in most modern plugin runtimes.

Here are the todo files:

```01-define-config-schema.md
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
```

```02-integrate-validation-and-error-reporting.md
# Wire Validation into Config Reading with Clear Error Messages

This todo integrates the schema from `01-define-config-schema.md` into the config
loading path so that bad configs fail loudly at read time rather than causing
confusing downstream errors during todo processing. All error messages should be
in the same language as the user's project — English is fine as a default since
config keys are English.

- [ ] Locate the function or code path that reads `.process-todos.json` (likely in a shared util or at the top of the `process-todos` skill/agent entrypoint)
- [ ] Replace the raw `JSON.parse` call with a wrapper function `loadProcessTodosConfig(projectRoot: string): ProcessTodosConfig` in `lib/load-config.ts`:
  1. Check if `.process-todos.json` exists; if not, return `DEFAULT_CONFIG` (no error)
  2. Read and `JSON.parse` the file — wrap in try/catch and surface a friendly message on JSON syntax errors: `"❌ .process-todos.json contains invalid JSON: <parse error message>. Fix the syntax and try again."`
  3. Run `ProcessTodosConfigSchema.safeParse(raw)` on the parsed value
  4. On failure, collect all Zod issues and format each as `"  • <field path>: <message>"` then throw with a multi-line error:
     ```
     ❌ .process-todos.json failed validation:
       • todo_path: Required
       • unknown_field: Unrecognized key
     Run `/process-todos help` to see the expected config shape.
     ```
  5. On success, return the typed config value
- [ ] Update all callers of the old config-reading code to use `loadProcessTodosConfig`
- [ ] Ensure the error is surfaced to the user in the skill/agent output (not swallowed), e.g., via a top-level `try/catch` that prints the error and exits early
- [ ] Add a brief config reference comment block at the top of `schemas/process-todos-config.ts` that lists all valid fields with types and defaults — this becomes the source of truth referenced in the error message's help hint
- [ ] Write tests in `lib/__tests__/load-config.test.ts`:
  - (a) missing `.process-todos.json` returns `DEFAULT_CONFIG` without error
  - (b) valid config file returns parsed config
  - (c) malformed JSON (syntax error) throws with message containing "invalid JSON"
  - (d) config with unknown key throws with message containing the key name
  - (e) config with wrong type (e.g. `todo_path: 123`) throws with message containing "todo_path"
  - (f) error message includes the help hint string
```

---

★ Insight ─────────────────────────────────────
- **`safeParse` vs `parse`**: Zod's `safeParse` returns `{ success, error }` instead of throwing directly, giving you full control over the error format. This is the right choice here so you can collect *all* validation errors at once rather than showing just the first one.
- **`.strict()` is underrated**: Without it, extra keys in the config are silently dropped. With it, typos like `"todo-path"` (hyphen instead of underscore) become visible errors instead of silent wrong-defaults bugs.
- **Separate schema from integration**: Keeping the Zod schema in its own file means it doubles as living documentation — any agent reading the plugin can check `schemas/process-todos-config.ts` to understand valid config without hunting through skill markdown.
─────────────────────────────────────────────────

두 파일을 `docs/todos/`에 저장하면 `/process-todos` 로 바로 처리할 수 있어. 순서가 중요해서 `01-` → `02-` 프리픽스로 넘버링했고, 스키마 정의가 먼저 완료돼야 validation 연동에서 import할 수 있어.
