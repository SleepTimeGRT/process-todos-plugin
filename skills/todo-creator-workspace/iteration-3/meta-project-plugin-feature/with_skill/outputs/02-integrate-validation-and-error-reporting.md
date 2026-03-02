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