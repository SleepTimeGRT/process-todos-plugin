```01-research-and-decide-validation-approach.md
# Research: Validation 접근법 결정

이 플러그인은 `.process-todos.json`을 설정 파일로 읽는다. 현재 config 읽기 로직이 어디에 있는지 파악하고, Zod vs JSON Schema 중 어떤 접근법이 이 프로젝트에 더 적합한지 결정한다. Claude Code 플러그인은 Node.js/TypeScript 환경에서 실행되므로 런타임 의존성 추가 여부도 고려해야 한다.

- [ ] 현재 `.process-todos.json`을 읽는 코드 위치를 찾는다 (Grep으로 `process-todos.json` 검색)
- [ ] 프로젝트의 `package.json`을 읽어 현재 의존성과 TypeScript 설정 확인
- [ ] `.process-todos.json`의 실제 필드 목록과 타입을 파악한다 (예시 파일 또는 README 참고)
- [ ] Zod 또는 JSON Schema 중 선택 결정: 이미 zod가 있으면 Zod, 없으면 경량 JSON Schema 검증 또는 Zod 신규 추가 여부 판단
- [ ] 선택한 접근법과 이유를 TODO 코멘트로 관련 파일에 기록
```

```02-define-config-schema.md
# Config Schema 정의

`.process-todos.json`의 기대 구조를 코드로 표현하는 스키마를 작성한다. 스키마는 타입 정의와 validation 로직을 동시에 제공해야 하며, 나중에 필드가 추가될 때 한 곳만 수정하면 되도록 단일 소스로 유지한다.

- [ ] config 스키마 파일 생성 (예: `src/config-schema.ts`)
- [ ] 모든 알려진 필드를 스키마에 정의한다 (필수/선택 구분 포함)
- [ ] 각 필드에 적절한 타입 제약을 추가한다 (예: 문자열 enum, 숫자 범위, 배열 요소 타입)
- [ ] 스키마에서 TypeScript 타입을 추론하거나 export한다 (`z.infer<typeof Schema>` 또는 동등한 방식)
- [ ] 빈 객체 `{}`도 유효한 config로 처리되도록 모든 필드를 optional로 처리 (기본값 적용 포함)
```

```03-integrate-validation-into-config-reader.md
# Config 읽기 로직에 Validation 통합

기존의 `.process-todos.json` 읽기 코드에 스키마 검증을 추가한다. 파일이 없거나 JSON parse 에러인 경우, 스키마 불일치인 경우를 각각 구분해서 처리해야 한다.

- [ ] 기존 config 읽기 함수를 찾아서 validation 단계를 추가할 위치를 파악
- [ ] JSON.parse 이후, 스키마 검증 호출을 삽입한다
- [ ] 검증 실패 시 `ValidationError` 또는 플러그인 기존 에러 패턴에 맞는 에러 객체를 throw
- [ ] 검증 성공 시 스키마에서 추론한 타입으로 반환값을 typed하게 처리
- [ ] 파일 없음(정상 케이스) vs JSON parse 실패 vs 스키마 불일치를 각각 다르게 처리
```

```04-design-error-messages.md
# 사용자 친화적 에러 메시지 설계

잘못된 설정에 대한 에러 메시지는 단순히 "invalid" 수준이 아니라, 어떤 필드가 문제인지, 어떤 값이 기대되는지를 명확히 알려줘야 한다. Claude Code 플러그인의 출력 스타일과 일치하도록 포맷을 맞춘다.

- [ ] 플러그인의 기존 에러 출력 방식을 확인한다 (콘솔 출력, throw, 또는 별도 에러 표시 메커니즘)
- [ ] Zod/JSON Schema의 에러 객체에서 필드 경로와 메시지를 추출하는 포매터 함수 작성
- [ ] 에러 메시지 형식 결정: 예) `❌ .process-todos.json 설정 오류\n  - "workers": 숫자여야 합니다 (받은 값: "auto")`
- [ ] 여러 필드가 동시에 잘못된 경우 모든 에러를 한 번에 출력하도록 처리 (첫 번째 에러에서 멈추지 않음)
- [ ] 에러 메시지에 `.process-todos.json` 파일 위치를 포함시켜 사용자가 바로 찾을 수 있도록
```

```05-write-tests.md
# Validation 로직 테스트 작성

스키마 검증이 실제로 의도대로 동작하는지 확인하는 테스트를 작성한다. 유효한 config, 부분적으로 유효한 config, 완전히 잘못된 config를 모두 커버해야 한다.

- [ ] 기존 테스트 파일 위치와 테스트 프레임워크(Jest/Vitest 등) 확인
- [ ] 유효한 config 입력에 대해 정상 파싱되는지 테스트
- [ ] 필수 필드 누락 시 에러가 throw되는지 테스트
- [ ] 타입이 잘못된 필드(예: 숫자 필드에 문자열) 입력 시 에러 메시지 내용 확인
- [ ] 알 수 없는 필드가 포함된 경우 동작 확인 (strict mode 여부에 따라 에러 또는 무시)
- [ ] 빈 `{}` config가 기본값으로 정상 처리되는지 확인
- [ ] 에러 메시지 포매터가 여러 에러를 올바르게 합쳐서 출력하는지 테스트
```
