# Config Schema 정의

`.process-todos.json`의 기대 구조를 코드로 표현하는 스키마를 작성한다. 스키마는 타입 정의와 validation 로직을 동시에 제공해야 하며, 나중에 필드가 추가될 때 한 곳만 수정하면 되도록 단일 소스로 유지한다.

- [ ] config 스키마 파일 생성 (예: `src/config-schema.ts`)
- [ ] 모든 알려진 필드를 스키마에 정의한다 (필수/선택 구분 포함)
- [ ] 각 필드에 적절한 타입 제약을 추가한다 (예: 문자열 enum, 숫자 범위, 배열 요소 타입)
- [ ] 스키마에서 TypeScript 타입을 추론하거나 export한다 (`z.infer<typeof Schema>` 또는 동등한 방식)
- [ ] 빈 객체 `{}`도 유효한 config로 처리되도록 모든 필드를 optional로 처리 (기본값 적용 포함)