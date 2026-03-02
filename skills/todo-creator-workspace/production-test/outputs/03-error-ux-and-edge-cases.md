# Polish Error UX and Handle Edge Cases

After the schema and validation logic are in place (todos 01 and 02), this todo handles the user-facing polish: making error messages helpful, handling tricky edge cases, and ensuring the validation gracefully degrades. Assumption: the project targets Korean-speaking developers primarily (user prompts are in Korean), so error messages should be bilingual or at least include Korean field descriptions alongside the technical English field names.

- [ ] Define a standard error message format in a new section of `schemas/process-todos-config.schema.json` (using `description` fields) or in a companion `schemas/error-messages.json` mapping each field to its Korean-language description:
  ```json
  {
    "todo_path": { "ko": "투두 파일 경로", "en": "todo file path" },
    "type_check_command": { "ko": "타입 체크 명령어", "en": "type check command" },
    "branch_prefix": { "ko": "브랜치 접두사", "en": "branch prefix" },
    "worker_model": { "ko": "워커 모델", "en": "worker model" }
  }
  ```
- [ ] Handle the edge case where `.process-todos.json` exists but is empty (0 bytes) — treat as `{}` (all defaults), do not error
- [ ] Handle the edge case where `.process-todos.json` contains JSON with BOM (byte order mark) — strip BOM before parsing, or note in instructions to handle this gracefully
- [ ] Handle the edge case where `todo_path` points to a non-existent directory — after validation passes, check directory existence and show: `"todo_path" 디렉토리가 존재하지 않습니다: {path}. 디렉토리를 생성하거나 경로를 확인해주세요.`
- [ ] Handle the edge case where `branch_prefix` contains characters invalid for git branch names (e.g., spaces, `~`, `^`, `:`) — add a pattern constraint or explicit check
- [ ] Add a `--validate-config` conceptual flow to the README: users can mentally validate their config by checking it against the schema, even though there is no CLI binary. Document how to use `npx ajv validate` directly if they want programmatic validation.
- [ ] Write tests in `schemas/__tests__/edge-cases.test.ts` covering:
  - Empty file treated as defaults
  - BOM-prefixed JSON parsed correctly
  - Deeply nested unexpected structure (e.g., `{ "todo_path": { "nested": true } }`) caught as type error
  - Unicode in `todo_path` (e.g., `"문서/투두"`) accepted as valid string
