# Research: Validation 접근법 결정

이 플러그인은 `.process-todos.json`을 설정 파일로 읽는다. 현재 config 읽기 로직이 어디에 있는지 파악하고, Zod vs JSON Schema 중 어떤 접근법이 이 프로젝트에 더 적합한지 결정한다. Claude Code 플러그인은 Node.js/TypeScript 환경에서 실행되므로 런타임 의존성 추가 여부도 고려해야 한다.

- [ ] 현재 `.process-todos.json`을 읽는 코드 위치를 찾는다 (Grep으로 `process-todos.json` 검색)
- [ ] 프로젝트의 `package.json`을 읽어 현재 의존성과 TypeScript 설정 확인
- [ ] `.process-todos.json`의 실제 필드 목록과 타입을 파악한다 (예시 파일 또는 README 참고)
- [ ] Zod 또는 JSON Schema 중 선택 결정: 이미 zod가 있으면 Zod, 없으면 경량 JSON Schema 검증 또는 Zod 신규 추가 여부 판단
- [ ] 선택한 접근법과 이유를 TODO 코멘트로 관련 파일에 기록