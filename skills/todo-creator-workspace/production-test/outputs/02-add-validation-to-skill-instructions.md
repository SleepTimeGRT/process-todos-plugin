# Add Validation Logic to Skill and Orchestrator Instructions

The schema defined in todo 01 needs to be enforced at the point where config is actually read — inside `skills/process-todos/SKILL.md` (the lead orchestrator) and `skills/todo-creator/SKILL.md` (the todo creator). Since these skills execute as Claude Code instructions (not as a Node.js program), validation is performed by instructing Claude Code to check each field against the schema rules after reading the JSON. This todo updates the markdown instructions to include validation steps and user-friendly error messages in Korean and English.

- [ ] In `skills/process-todos/SKILL.md`, update "Step 0 — Load Configuration" to add a validation sub-step after reading `.process-todos.json`:
  1. After reading the JSON, check each field against expected types and constraints:
     - `todo_path`: must be a string if present
     - `type_check_command`: must be a string if present
     - `branch_prefix`: must be a string ending with `/` if present
     - `worker_model`: must be one of `"sonnet"`, `"opus"`, `"haiku"`, or `null` if present
  2. Check for any unrecognized top-level keys (fields not in the schema) and warn about them
  3. If validation fails, show a clear error message listing each problem and stop execution. Example format:
     ```
     Configuration error in .process-todos.json:
     - "branch_prefix": expected a string ending with "/" but got "no-slash"
     - "worker_model": expected one of "sonnet", "opus", "haiku", or null but got "gpt-4"
     ```
  4. If JSON parsing itself fails (malformed JSON), show: `Failed to parse .process-todos.json: <error detail>. Please check that the file contains valid JSON.`
- [ ] In `skills/todo-creator/SKILL.md`, update "Step 1 — Load Configuration" with the same validation logic described above, keeping the instructions consistent between both skills
- [ ] Add a note in both skills referencing `schemas/process-todos-config.schema.json` as the authoritative schema definition, so future maintainers know where the source of truth lives
- [ ] Update `README.md` to document the validation behavior:
  - Add a section "Configuration Validation" explaining that invalid config produces actionable error messages
  - Document the allowed values for `worker_model` explicitly
  - Add an example of what an error message looks like for common mistakes
- [ ] Write integration-level test scenarios (documented in `schemas/__tests__/validation-scenarios.md`) describing:
  - (a) Skill reads valid config and proceeds normally
  - (b) Skill reads config with unknown field and warns but continues (or errors — decide which)
  - (c) Skill reads config with wrong-type field and stops with clear error
  - (d) Skill reads malformed JSON (trailing comma, missing quote) and shows parse error
  - (e) Skill reads absent `.process-todos.json` and uses defaults without error
